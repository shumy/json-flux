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
    println('Activate JFlux')
    ws = new WebSocketServer(false, 8080, '/websocket')
    ws.start
  }
  
  @Deactivate
  def void stop() {
    println('Deactivate JFlux')
    ws.stop
  }
}