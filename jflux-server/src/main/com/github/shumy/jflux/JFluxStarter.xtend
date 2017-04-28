package com.github.shumy.jflux

import com.fasterxml.jackson.databind.ObjectMapper
import com.github.shumy.jflux.msg.JMessage
import com.github.shumy.jflux.pipeline.Pipeline
import com.github.shumy.jflux.ws.WebSocketServer
import org.osgi.service.component.annotations.Activate
import org.osgi.service.component.annotations.Component
import org.osgi.service.component.annotations.Deactivate

@Component
class JFluxStarter {
  var WebSocketServer<JMessage> ws
  
  @Activate
  def void start() {
    val mapper = new ObjectMapper
    val (String) => JMessage decoder = [ mapper.readValue(it, JMessage) ]
    val (JMessage) => String encoder = [ mapper.writeValueAsString(it) ]
    
    val pipe = new Pipeline<JMessage> => [
      handler[
        val vError = msg.validateEntry
        if (vError !== null) {
          send(JMessage.replyError(msg.id, vError))
          return
         }
        
        val data = mapper.valueToTree(#{ 'x' -> 10, 'y' -> 25 })
        val reply = JMessage.requestReply(msg.id, data)
        
        send(reply)
        next
      ]
      onFail = [
        println('PIPELINE-ERROR:')
        printStackTrace
      ]
    ]
    
    ws = new WebSocketServer<JMessage>(false, 8080, '/websocket', decoder, encoder)[
      println('''Open(«Thread.currentThread.name»): «id»''')
      onClose = [ println('''Close(«Thread.currentThread.name»): «id»''') ]
      
      onMessage = [ msg |
        println('''Message(«Thread.currentThread.name»): «msg»''')
        pipe.process(it, msg)
      ]
    ]
    
    ws.start
  }
  
  @Deactivate
  def void stop() {
    ws.stop
  }
}