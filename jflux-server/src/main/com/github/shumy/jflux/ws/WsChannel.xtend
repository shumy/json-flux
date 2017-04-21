package com.github.shumy.jflux.ws

import com.github.shumy.jflux.pipeline.IChannel
import io.netty.channel.Channel
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame
import io.netty.handler.codec.http.websocketx.WebSocketFrame
import org.eclipse.xtend.lib.annotations.Accessors
import org.slf4j.LoggerFactory

class WsChannel implements IChannel {
  static val logger = LoggerFactory.getLogger(WsChannel)
  
  val WebSocketServer srv
  val Channel ch
  val sb = new StringBuffer
  
  @Accessors var (String) => void onMessage
  @Accessors var () => void onClose
  
  override getId() { return ch.id.asShortText }
  
  override send(String msg) {
    logger.debug("Channel({}) -> SND-MSG: {}", id, msg)
    
    val frame = new TextWebSocketFrame(msg)
    if (ch.eventLoop.inEventLoop)
      ch.writeAndFlush(frame)
    else ch.eventLoop.execute[
      ch.writeAndFlush(frame)
    ]
  }
  
  override close() {
    logger.debug("Channel({}) -> CLOSE", id)
    if (ch.open) ch.close
    
    srv.channels.remove(id)
    onClose?.apply
  }
  
  package new(WebSocketServer srv, Channel ch) {
    this.srv = srv
    this.ch = ch
    logger.debug("Channel({}) -> OPEN", id)
  }
  
  package def nextFrame(WebSocketFrame frame) {
    if (frame instanceof TextWebSocketFrame) {
      sb.append(frame.text)
      
      if (frame.finalFragment) {
        val msg = sb.toString
        sb.length = 0
        logger.debug("Channel({}) -> RCV-MSG: {}", id, msg)
        onMessage?.apply(msg)
      }
    } else //BinaryWebSocketFrame
      throw new UnsupportedOperationException('''Unsupported frame type: «frame.class.name»''')
  }
}