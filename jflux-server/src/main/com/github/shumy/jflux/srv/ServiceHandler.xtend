package com.github.shumy.jflux.srv

import com.fasterxml.jackson.databind.ObjectMapper
import com.github.shumy.jflux.api.IRequest
import com.github.shumy.jflux.api.IStream
import com.github.shumy.jflux.msg.Command
import com.github.shumy.jflux.msg.Flag
import com.github.shumy.jflux.msg.JError
import com.github.shumy.jflux.msg.JMessage
import com.github.shumy.jflux.pipeline.PContext
import com.github.shumy.jflux.srv.ServiceMethod.Type
import com.github.shumy.jflux.srv.async.JRequestResult
import com.github.shumy.jflux.srv.async.JStreamResult

class ServiceHandler implements (PContext<JMessage>)=>void {
  val mapper = new ObjectMapper
  val store = new ServiceStore(mapper)
  
  def void addService(Object srv) {
    store.addService(srv)
  }
  
  override apply(PContext<JMessage> it) {
    if (msg.cmd === null) {
      send(JMessage.replyError(msg.id, new JError(400, 'No mandatory field (cmd)')))
      return
    }
    
    if (msg.cmd === Command.SEND && msg.id === null) {
      send(JMessage.replyError(msg.id, new JError(400, 'No mandatory field (id) for (send)')))
      return
    }
    
    if (msg.cmd === Command.REPLY) {
      send(JMessage.replyError(msg.id, new JError(400, 'Receiving a (reply) is not valid!')))
      return
    }
    
    if (msg.cmd === Command.PUBLISH)
      processPublish
    else
      processSend
  }
  
  def void processPublish(PContext<JMessage> it) {
    if (msg.flag === null) {
      val sm = serviceMethod
      if (sm === null) return;
      
      if (sm.type === Type.PUBLISH) {
        val ret = sm.invoke(msg)
        if (ret instanceof JError)
          send(JMessage.replyError(msg.id, ret))
      } else
        send(JMessage.replyError(msg.id, new JError(400, 'Invalid (fire-and-forget) method: ' + sm.name)))
    } else if (msg.flag === Flag.CANCEL) {
      if (msg.suid === null) {
        send(JMessage.replyError(msg.id, new JError(400, 'No mandatory fields (suid) for (cancel)')))
        return
      }
      
      val stream = channel.store.remove(msg.suid) as JStreamResult
      stream?.cancel
    } else
      send(JMessage.replyError(msg.id, new JError(400, 'No flux available for (publish)!')))
  }
  
  def void processSend(PContext<JMessage> it) {
    if (msg.flag === null) {
      val sm = serviceMethod
      if (sm === null) return;
       
      val ret = sm.invoke(msg)
      if (ret instanceof JError) {
        send(JMessage.replyError(msg.id, ret))
        return
      }
      
      if (sm.type === Type.REQUEST)
        processRequest(ret)
      else if (sm.type === Type.STREAM)
        processStream(ret)
      else
        send(JMessage.replyError(msg.id, new JError(400, 'Invalid (request/reply) or (request/stream) method: ' + sm.name)))
    } else if (msg.flag === Flag.SUBSCRIBE) {
      //TODO: process (SEND, SUBCRIBE) for channels
      println('Channel subscription not yet implemented!')
      send(JMessage.replyError(msg.id, new JError(500, 'Channel subscription not yet implemented!')))
    } else
      send(JMessage.replyError(msg.id, new JError(400, 'No flux available for (send)!')))
  }
  
  def void processRequest(PContext<JMessage> it, Object ret) {
    if (ret instanceof IRequest<?>) {
      new Thread[
        try {
          val request = ret as IRequest<Object>
          request.apply(new JRequestResult(it))
        } catch (Throwable ex) {
          ex.printStackTrace
          send(JMessage.replyError(msg.id, new JError(500, ex.message)))
        }
      ].start
    } else {
      val value = mapper.valueToTree(ret)
      send(JMessage.requestReply(msg.id, value))
    }
  }
  
  def void processStream(PContext<JMessage> it, Object ret) {
    val sr = new JStreamResult(it)
    channel.store.put(sr.suid, sr)
    send(JMessage.streamReply(msg.id, sr.suid))
    
    new Thread[
      try {
        val stream = ret as IStream<Object>
        stream.apply(sr)
      } catch (Throwable ex) {
        ex.printStackTrace
        channel.store.remove(sr.suid)
        send(JMessage.publishError(msg.id, sr.suid, new JError(500, ex.message)))
      }
    ].start
  }
  
  def ServiceMethod serviceMethod(PContext<JMessage> it) {
    val sPath = msg.path.split(':')
    if (sPath.length !== 3 || sPath.get(0) != 'srv') {
      send(JMessage.replyError(msg.id, new JError(400, 'Service path not valid: ' + msg.path)))
      return null
    }
    
    val sm = store.getMethod(sPath.get(1), sPath.get(2))
    if (sm === null) {
      send(JMessage.replyError(msg.id, new JError(404, 'Service path not found: ' + msg.path)))
      return null
    }
    
    return sm
  }
}