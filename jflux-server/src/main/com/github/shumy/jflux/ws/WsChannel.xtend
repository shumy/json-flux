package com.github.shumy.jflux.ws

import com.github.shumy.jflux.pipeline.PChannel
import com.github.shumy.jflux.pipeline.Pipeline
import io.netty.channel.Channel
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame
import io.netty.handler.codec.http.websocketx.WebSocketFrame
import java.util.Map
import java.util.concurrent.ConcurrentHashMap
import org.eclipse.xtend.lib.annotations.Accessors
import org.slf4j.LoggerFactory

class WsChannel<MSG> implements PChannel<MSG> {
  static val logger = LoggerFactory.getLogger(WsChannel)
  
  val WebSocketServer<MSG> srv
  val Channel ch
  
  val sb = new StringBuffer
  
  var Pipeline<MSG> pipe
  @Accessors var () => void onClose
  
  @Accessors val Map<String, Object> store = new ConcurrentHashMap<String, Object>
  
  override getId() { return ch.id.asShortText }
  
  override send(MSG msg) {
    try {
      val txt = srv.encoder.apply(msg)
      logger.debug("Channel({}) -> SND-MSG: {}", id, txt)
      
      val frame = new TextWebSocketFrame(txt)
      if (ch.eventLoop.inEventLoop)
        ch.writeAndFlush(frame)
      else ch.eventLoop.execute[
        ch.writeAndFlush(frame)
      ]
    } catch(Throwable ex) {
      pipe?.fail(ex)
    }
  }
  
  override link(Pipeline<MSG> pipe) {
    this.pipe = pipe
  }
  
  override close() {
    logger.debug("Channel({}) -> CLOSE", id)
    if (ch.open) ch.close
    
    srv.channels.remove(id)
    onClose?.apply
  }
  
  package new(WebSocketServer<MSG> srv, Channel ch) {
    this.srv = srv
    this.ch = ch
    logger.debug("Channel({}) -> OPEN", id)
  }
  
  package def nextFrame(WebSocketFrame frame) {
    try {
      if (frame instanceof TextWebSocketFrame) {
        sb.append(frame.text)
        
        if (frame.finalFragment) {
          val txt = sb.toString
          sb.length = 0
          
          
            logger.debug("Channel({}) -> RCV-MSG: {}", id, txt)
            val msg = srv.decoder.apply(txt)
            pipe?.process(this, msg)
        }
      } else //BinaryWebSocketFrame
        throw new UnsupportedOperationException('''Unsupported frame type: «frame.class.name»''')
    } catch(Throwable ex) {
      pipe?.fail(ex)
    }
  }
}