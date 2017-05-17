package com.github.shumy.jflux.srv

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.node.ArrayNode
import com.github.shumy.jflux.api.Channel
import com.github.shumy.jflux.api.IChannel
import com.github.shumy.jflux.api.IRequest
import com.github.shumy.jflux.api.IStream
import com.github.shumy.jflux.api.Init
import com.github.shumy.jflux.api.Publish
import com.github.shumy.jflux.api.Request
import com.github.shumy.jflux.api.Service
import com.github.shumy.jflux.api.Stream
import com.github.shumy.jflux.api.store.IMethod
import com.github.shumy.jflux.api.store.IServiceStore
import com.github.shumy.jflux.msg.JError
import com.github.shumy.jflux.msg.JMessage
import com.github.shumy.jflux.srv.async.JChannel
import java.lang.reflect.Method
import java.util.Collections
import java.util.Map
import java.util.concurrent.ConcurrentHashMap
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.osgi.service.component.annotations.Component
import org.slf4j.LoggerFactory

@Component
class ServiceStore implements IServiceStore {
  static val logger = LoggerFactory.getLogger(ServiceStore)
  
  val mapper = new ObjectMapper
  val paths = new ConcurrentHashMap<String, Map<String, Object>> //Object of types: ServiceMethod or JChannel
  
  override getServices() {
    Collections.unmodifiableList(paths.keySet.toList)
  }
  
  override getPaths(String srv) {
    Collections.unmodifiableMap(paths.get(srv)?: Collections.EMPTY_MAP)
  }
  
  override addService(Object srv) {
    val srvName = srv.class.name
    addService(srvName, srv)
  }
  
  override addService(String srvName, Object srv) {
    var Method initMeth = null
    
    if (srv.class.getAnnotation(Service) === null)
      throw new RuntimeException('''Class «srvName» is not a service!''')
      
    logger.debug("ADD-SRV: {}", srvName)
    var srvMap = paths.get(srvName)
    if (srvMap === null) {
      srvMap = new ConcurrentHashMap<String, Object>
      paths.put(srvName, srvMap)
    }
    
    for(meth: srv.class.declaredMethods) {
      if (meth.getAnnotation(Publish) !== null) {
        if (meth.returnType != void)
          throw new RuntimeException('''Publish method («srvName»:«meth.name») should not have any return type''')
        
        srvMap.put(meth.name, new ServiceMethod(mapper, IMethod.Type.PUBLISH, srv, meth))
        logger.debug("ADD-METH-PUBLISH: {}", meth.name)
      }
      
      if (meth.getAnnotation(Request) !== null) {
        if (meth.returnType != IRequest && !mapper.canSerialize(meth.returnType))
          throw new RuntimeException('''Request method («srvName»:«meth.name») invalid return type''')
        
        srvMap.put(meth.name, new ServiceMethod(mapper, IMethod.Type.REQUEST, srv, meth))
        logger.debug("ADD-METH-REQUEST: {}", meth.name)
      }
      
      if (meth.getAnnotation(Stream) !== null) {
        if (meth.returnType != IStream)
          throw new RuntimeException('''Stream method («srvName»:«meth.name») should return IStream<D>''')
          
        srvMap.put(meth.name, new ServiceMethod(mapper, IMethod.Type.STREAM, srv, meth))
        logger.debug("ADD-METH-STREAM: {}", meth.name)
      }
      
      if (meth.getAnnotation(Init) !== null) {
        if (meth.parameterCount !== 0)
          throw new RuntimeException('''Init method («srvName»:«meth.name») should not have any parameters''')
        
        initMeth = meth
      }
    }
    
    for (field: srv.class.declaredFields) {
      val fAnno = field.getAnnotation(Channel)
      if (fAnno !== null) {
        if (field.type != IChannel)
          throw new RuntimeException('''Channel field («field.type.name») should be of type IChannel''')
        
        val ch = new JChannel(fAnno.value)
        srvMap.put(field.name, ch)
        
        field.accessible = true
        field.set(srv, ch)
        
        logger.debug("ADD-CHANNEL: {}", field.name)
      }
    }
    
    initMeth?.invoke(srv)
  }
  
  override removeService(String srvName) {
    paths.remove(srvName)
  }
  
  override getMethod(String srvName, String methName) {
    val srvMap = paths.get(srvName)
    return srvMap?.get(methName) as ServiceMethod
  }
  
  override getChannel(String srvName, String methName) {
    val srvMap = paths.get(srvName)
    return srvMap?.get(methName) as JChannel
  }
}

@FinalFieldsConstructor
class ServiceMethod implements IMethod {
  val ObjectMapper mapper
  @Accessors val Type type
  val Object srv
  val Method meth
  
  override getName() {return meth.name }
  override getReturnTypeName() { meth.returnType.simpleName }
  
  override getParameterTypesName() {
    meth.parameterTypes.map[ simpleName ]
  }
  
  def Object invoke(JMessage it) {
    //BEGIN: parameter conversion
    val argTypes = meth.parameterTypes
    val args = newArrayOfSize(meth.parameterCount)
    
    if (meth.parameterCount > 1) {
      if (!data.array || (data as ArrayNode).size !== meth.parameterCount)
        return new JError(400, 'Invalid number of arguments for path: ' + path)
      
      var n = 0
      for (item: data) {
        val value = mapper.treeToValue(item, argTypes.get(n))
        args.set(n, value)
        n++
      }
    } else if (meth.parameterCount == 1) {
      val value = mapper.treeToValue(data, argTypes.get(0))
      args.set(0, value)
    }
    //END: parameter conversion
    
    try {
      return meth.invoke(srv, args)
    } catch (Throwable error) {
      return new JError(500, error.message)
    }
  }
}