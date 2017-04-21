package com.github.shumy.jflux.ws

import io.netty.channel.Channel
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame
import io.netty.handler.codec.http.websocketx.WebSocketFrame
import org.eclipse.xtend.lib.annotations.Accessors
import org.slf4j.LoggerFactory

class WsChannel {
  static val logger = LoggerFactory.getLogger(WsChannel)
  
  val WebSocketServer srv
  val Channel ch
  val sb = new StringBuffer
  
  @Accessors var (String) => void onMessage
  @Accessors var () => void onClose
  
  def getId() { return ch.id.asShortText }
  
  def void write(String msg) {
    ch.writeAndFlush(new TextWebSocketFrame(msg))
  }
  
  def void close() {
    if (ch.open) ch.close
    
    srv.channels.remove(id)
    onClose?.apply
    logger.debug("Channel close {}", id)
  }
  
  package new(WebSocketServer srv, Channel ch) {
    this.srv = srv
    this.ch = ch
    logger.debug("Channel open {}", ch.id.asShortText)
  }
  
  package def nextFrame(WebSocketFrame frame) {
    if (frame instanceof TextWebSocketFrame) {
      sb.append(frame.text)
      
      if (frame.finalFragment) {
        val txtMsg = sb.toString
        sb.length = 0
        logger.debug("Channel {} text: {}", id, txtMsg)
        onMessage?.apply(txtMsg)
      }
    } else //BinaryWebSocketFrame
      throw new UnsupportedOperationException('''Unsupported frame type: «frame.class.name»''')
  }
}