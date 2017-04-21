package com.github.shumy.jflux

import com.fasterxml.jackson.databind.ObjectMapper
import com.github.shumy.jflux.pipeline.PMessage
import com.github.shumy.jflux.pipeline.Pipeline
import com.github.shumy.jflux.ws.WebSocketServer
import org.osgi.service.component.annotations.Activate
import org.osgi.service.component.annotations.Component
import org.osgi.service.component.annotations.Deactivate

@Component
class JFluxStarter {
  var WebSocketServer ws
  
  @Activate
  def void start() {
    val mapper = new ObjectMapper
    val (String) => PMessage decoder = [ mapper.readValue(it, PMessage) ]
    val (PMessage) => String encoder = [ mapper.writeValueAsString(it) ]
    
    val pipe = new Pipeline(decoder, encoder) => [
      handler[ println(msg.toString) ]
      onFail = [
        println('PIPELINE-ERROR:')
        printStackTrace
      ]
    ]
    
    ws = new WebSocketServer(false, 8080, '/websocket')[
      println('''Open(«Thread.currentThread.name»): «id»''')
      onClose = [ println('''Close(«Thread.currentThread.name»): «id»''') ]
      
      onMessage = [ json |
        println('''Message(«Thread.currentThread.name»): «json»''')
        pipe.process(it, json)
      ]
    ]
    
    ws.start
  }
  
  @Deactivate
  def void stop() {
    ws.stop
  }
}