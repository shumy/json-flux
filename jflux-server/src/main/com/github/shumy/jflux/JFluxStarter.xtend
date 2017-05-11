package com.github.shumy.jflux

import com.github.shumy.jflux.msg.JMessage
import com.github.shumy.jflux.msg.JMessageConverter
import com.github.shumy.jflux.pipeline.Pipeline
import com.github.shumy.jflux.srv.HelloService
import com.github.shumy.jflux.srv.handler.ServiceHandler
import com.github.shumy.jflux.srv.handler.SignalHandler
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
      addService('Hello', new HelloService)
    ]
    
    val pipe = new Pipeline<JMessage> => [
      handler(srvHandler)
      handler(new SignalHandler)
      onFail = [
        println('PIPELINE-ERROR:')
        printStackTrace
        //TODO: send (SIGNAL, ERROR) ?
      ]
    ]
    
    val mc = new JMessageConverter
    ws = new WebSocketServer<JMessage>(false, 8080, '/ws', mc.initDataDecoder, mc.msgDecoder, mc.msgEncoder)[ ch |
      pipe.process(ch, JMessage.signalOpen)
      ch.onClose = [ pipe.process(ch, JMessage.signalClose) ]
      ch.link(pipe)
    ]
    
    ws.start
  }
  
  @Deactivate
  def void stop() {
    ws.stop
  }
}