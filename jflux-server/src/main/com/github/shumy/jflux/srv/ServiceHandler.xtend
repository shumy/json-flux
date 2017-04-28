package com.github.shumy.jflux.srv

import com.fasterxml.jackson.databind.ObjectMapper
import com.github.shumy.jflux.api.IRequest
import com.github.shumy.jflux.api.IStream
import com.github.shumy.jflux.msg.Flag
import com.github.shumy.jflux.msg.JError
import com.github.shumy.jflux.msg.JMessage
import com.github.shumy.jflux.pipeline.PContext
import com.github.shumy.jflux.srv.ServiceMethod.Type
import com.github.shumy.jflux.srv.async.JRequestResult
import com.github.shumy.jflux.srv.async.JStreamResult
import java.util.concurrent.ConcurrentHashMap

class ServiceHandler implements (PContext<JMessage>)=>void {
  val mapper = new ObjectMapper
  val store = new ServiceStore(mapper)
  val streams = new ConcurrentHashMap<String, JStreamResult>
  
  def void addService(Object srv) {
    store.addService(srv)
  }
  
  override apply(PContext<JMessage> it) {
    val vError = msg.validateEntry
    if (vError !== null) {
      send(JMessage.replyError(msg.id, vError))
      return
    }
    
    val sPath = msg.path.split(':')
    if (sPath.length !== 3 || sPath.get(0) != 'srv') {
      send(JMessage.replyError(msg.id, new JError(400, 'Service path not valid: ' + msg.path)))
      return
    }
    
    if (msg.flag === null) {
      //method call: (SEND) or (PUBLISH)
      val sm = store.getMethod(sPath.get(1), sPath.get(2))
      if (sm === null) {
        send(JMessage.replyError(msg.id, new JError(404, 'Service path not found: ' + msg.path)))
        return
      }
      
      val ret = sm.invoke(msg)
      if (ret instanceof JError) {
        send(JMessage.replyError(msg.id, ret))
        return
      }
      
      if (sm.type == Type.REQUEST) {
        processRequest(ret)
        return
      }
      
      if (sm.type == Type.STREAM) {
        processStream(ret)
        return
      }
      
    } else {
      //(SEND, SUBSCRIBE) or (PUBLISH, CANCEL)
      if (msg.flag == Flag.CANCEL) {
        val stream = streams.remove(msg.suid)
        stream?.cancel
      }
    }
  }
  
  def void processRequest(PContext<JMessage> it, Object ret) {
    if (ret instanceof IRequest) {
      new Thread[
        ret.apply(new JRequestResult(it))
      ].start
      return
    }
    
    val value = mapper.valueToTree(ret)
    send(JMessage.requestReply(msg.id, value))
  }
  
  def void processStream(PContext<JMessage> it, Object ret) {
    val sr = new JStreamResult(it)
    streams.put(sr.suid, sr)
    send(JMessage.streamReply(msg.id, sr.suid))
    
    new Thread[
      val stream = ret as IStream<Object>
      stream.apply(sr)
    ].start
  }
}