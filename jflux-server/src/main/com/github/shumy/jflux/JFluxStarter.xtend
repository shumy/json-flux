package com.github.shumy.jflux

import com.github.shumy.jflux.ws.WebSocketServer
import org.osgi.service.component.annotations.Activate
import org.osgi.service.component.annotations.Component
import org.osgi.service.component.annotations.Deactivate

@Component
class JFluxStarter {
  var WebSocketServer ws
  
  @Activate
  def void start() {
    ws = new WebSocketServer(false, 8080, '/websocket')[
      println('''Open(«Thread.currentThread.name»): «id»''')
      onClose = [ println('''Close(«Thread.currentThread.name»): «id»''') ]
      
      onMessage = [ msg |
        println('''Message(«Thread.currentThread.name»): «msg»''')
        write(msg.toUpperCase)
      ]
    ]
    
    ws.start
  }
  
  @Deactivate
  def void stop() {
    ws.stop
  }
}