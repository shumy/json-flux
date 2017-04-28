package com.github.shumy.jflux

import com.github.shumy.jflux.msg.JMessage
import com.github.shumy.jflux.msg.JMessageConverter
import com.github.shumy.jflux.pipeline.Pipeline
import com.github.shumy.jflux.srv.HelloService
import com.github.shumy.jflux.srv.ServiceHandler
import com.github.shumy.jflux.ws.WebSocketServer
import org.osgi.service.component.annotations.Activate
import org.osgi.service.component.annotations.Component
import org.osgi.service.component.annotations.Deactivate

@Component
class JFluxStarter {
  var WebSocketServer<JMessage> ws
  
  @Activate
  def void start() {
    val srvHandler = new ServiceHandler => [
      addService(new HelloService)
    ]
    
    val pipe = new Pipeline<JMessage> => [
      handler(srvHandler)
      onFail = [
        println('PIPELINE-ERROR:')
        printStackTrace
      ]
    ]
    
    val mc = new JMessageConverter
    ws = new WebSocketServer<JMessage>(false, 8080, '/ws', mc.decoder, mc.encoder)[
      println('''Open(«Thread.currentThread.name»): «id»''')
      onClose = [ println('''Close(«Thread.currentThread.name»): «id»''') ]
      
      link(pipe)
    ]
    
    ws.start
  }
  
  @Deactivate
  def void stop() {
    ws.stop
  }
}