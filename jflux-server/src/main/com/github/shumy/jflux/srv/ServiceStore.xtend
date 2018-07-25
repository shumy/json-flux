package com.github.shumy.jflux.srv

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.node.ArrayNode
import com.github.shumy.jflux.api.Channel
import com.github.shumy.jflux.api.Doc
import com.github.shumy.jflux.api.IChannel
import com.github.shumy.jflux.api.IRequest
import com.github.shumy.jflux.api.IStream
import com.github.shumy.jflux.api.ISubscription
import com.github.shumy.jflux.api.Init
import com.github.shumy.jflux.api.Publish
import com.github.shumy.jflux.api.Request
import com.github.shumy.jflux.api.Service
import com.github.shumy.jflux.api.Stream
import com.github.shumy.jflux.api.store.ChannelDesc
import com.github.shumy.jflux.api.store.IMethod
import com.github.shumy.jflux.api.store.IServiceStore
import com.github.shumy.jflux.api.store.MethodDesc
import com.github.shumy.jflux.api.store.ParamDesc
import com.github.shumy.jflux.api.store.ServiceDesc
import com.github.shumy.jflux.msg.JError
import com.github.shumy.jflux.msg.JMessage
import com.github.shumy.jflux.srv.async.JChannel
import java.lang.reflect.Field
import java.lang.reflect.Method
import java.util.ArrayList
import java.util.Collections
import java.util.Map
import java.util.concurrent.ConcurrentHashMap
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.osgi.service.component.annotations.Component
import org.slf4j.LoggerFactory
import java.util.UUID

@Component
class ServiceStore implements IServiceStore {
  static val logger = LoggerFactory.getLogger(ServiceStore)
  
  val mapper = new ObjectMapper
  
  val services = new ConcurrentHashMap<String, ServiceDesc>
  package val onAddSubs = new ConcurrentHashMap<String, ServiceSubscription<ServiceDesc>>
  package val onRemoveSubs = new ConcurrentHashMap<String, ServiceSubscription<String>>
  
  val paths = new ConcurrentHashMap<String, Map<String, Object>> //Object of types: ServiceMethod or JChannel
  
  private def createMethDesc(Method meth, String modeType) {
    val paramList = Collections.unmodifiableList(meth.parameters.map[ new ParamDesc(name, type.simpleName, getAnnotation(Doc)) ])
    return new MethodDesc(meth.name, modeType, meth.getAnnotation(Doc), meth.returnType.simpleName, paramList)
  }
  
  private def createChannelDesc(Field field, Class<?> msgType) {
    return new ChannelDesc(field.name, msgType.simpleName, field.getAnnotation(Doc))
  }
  
  override getServices() {
    Collections.unmodifiableList(services.values.toList)
  }
  
  override getService(String name) {
    services.get(name)
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
    
    val methDescList = new ArrayList<MethodDesc>
    for(meth: srv.class.declaredMethods) {
      if (meth.getAnnotation(Publish) !== null) {
        if (meth.returnType != void)
          throw new RuntimeException('''Publish method («srvName»:«meth.name») should not have any return type''')
        
        srvMap.put(meth.name, new ServiceMethod(mapper, IMethod.Type.PUBLISH, srv, meth))
        methDescList.add(meth.createMethDesc(IMethod.Type.PUBLISH.name))
        logger.debug("ADD-METH-PUBLISH: {}", meth.name)
      }
      
      if (meth.getAnnotation(Request) !== null) {
        if (meth.returnType != IRequest && !mapper.canSerialize(meth.returnType))
          throw new RuntimeException('''Request method («srvName»:«meth.name») invalid return type''')
        
        srvMap.put(meth.name, new ServiceMethod(mapper, IMethod.Type.REQUEST, srv, meth))
        methDescList.add(meth.createMethDesc(IMethod.Type.REQUEST.name))
        logger.debug("ADD-METH-REQUEST: {}", meth.name)
      }
      
      if (meth.getAnnotation(Stream) !== null) {
        if (meth.returnType != IStream)
          throw new RuntimeException('''Stream method («srvName»:«meth.name») should return IStream<D>''')
          
        srvMap.put(meth.name, new ServiceMethod(mapper, IMethod.Type.STREAM, srv, meth))
        methDescList.add(meth.createMethDesc(IMethod.Type.STREAM.name))
        logger.debug("ADD-METH-STREAM: {}", meth.name)
      }
      
      if (meth.getAnnotation(Init) !== null) {
        if (meth.parameterCount !== 0)
          throw new RuntimeException('''Init method («srvName»:«meth.name») should not have any parameters''')
        
        initMeth = meth
        methDescList.add(meth.createMethDesc(IMethod.Type.INIT.name))
        logger.debug("ADD-METH-INIT: {}", meth.name)
      }
    }
    
    val channelDescList = new ArrayList<ChannelDesc>
    for (field: srv.class.declaredFields) {
      val fAnno = field.getAnnotation(Channel)
      if (fAnno !== null) {
        if (field.type != IChannel)
          throw new RuntimeException('''Channel field («field.type.name») should be of type IChannel''')
        
        val ch = new JChannel(fAnno.value)
        srvMap.put(field.name, ch)
        
        field.accessible = true
        field.set(srv, ch)
        
        channelDescList.add(field.createChannelDesc(fAnno.value))
        logger.debug("ADD-CHANNEL: {}", field.name)
      }
    }
    
    initMeth?.invoke(srv)
    
    val srvDesc = new ServiceDesc(srvName, srv.class.getAnnotation(Doc), Collections.unmodifiableList(channelDescList), Collections.unmodifiableList(methDescList))
    services.put(srvName, srvDesc)
    onAddSubs.values.forEach[
      onEvent?.apply(srvDesc)
    ]
  }
  
  override removeService(String srvName) {
    onRemoveSubs.values.forEach[
      onEvent?.apply(srvName)
    ]
    
    services.remove(srvName)
    paths.remove(srvName)
  }
  
  override onAdd((ServiceDesc)=>void onAdd) {
    val suid = UUID.randomUUID.toString
    val sub = new ServiceSubscription<ServiceDesc>(this, suid, ServiceSubscription.Event.ADD, onAdd)
    onAddSubs.put(suid, sub)
    
    return sub
  }
  
  override onRemove((String)=>void onRemove) {
    val suid = UUID.randomUUID.toString
    val sub = new ServiceSubscription<String>(this, suid, ServiceSubscription.Event.REMOVE, onRemove)
    onRemoveSubs.put(suid, sub)
    
    return sub
  }
  
  override getMethod(String srvName, String methName) {
    val srvMap = paths.get(srvName)
    return srvMap?.get(methName) as ServiceMethod
  }
  
  override getChannel(String srvName, String chlName) {
    val srvMap = paths.get(srvName)
    return srvMap?.get(chlName) as JChannel
  }
}

@FinalFieldsConstructor
class ServiceSubscription<T> implements ISubscription {
  enum Event { ADD, REMOVE }
  
  val ServiceStore ss
  val String suid
  
  public val Event event
  public val (T)=>void onEvent
  
  override suid() { suid }
  
  override cancel() {
    if (event === Event.ADD)
      ss.onAddSubs.remove(suid)
    else
      ss.onRemoveSubs.remove(suid)
  }
}

@FinalFieldsConstructor
class ServiceMethod implements IMethod {
  val ObjectMapper mapper
  @Accessors val Type type
  val Object srv
  val Method meth
  
  override getName() { meth.name }
  
  override getReturnType() { meth.returnType.simpleName }
  
  override getParamTypes() {
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