package com.github.shumy.jflux.ws

import com.github.shumy.jflux.pipeline.PChannel
import io.netty.channel.Channel
import io.netty.handler.codec.http.QueryStringDecoder
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame
import io.netty.handler.codec.http.websocketx.WebSocketFrame
import java.util.Base64
import java.util.Collections
import java.util.Map
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicReference
import org.eclipse.xtend.lib.annotations.Accessors
import org.slf4j.LoggerFactory

class WsChannel<MSG> implements PChannel<MSG> {
  static val logger = LoggerFactory.getLogger(WsChannel)
  
  enum State { TRY, READY, CLOSED }
  
  val WebSocketServer<MSG> srv
  val Channel ch
  
  val state = new AtomicReference<State>(State.TRY)
  val sb = new StringBuffer
  
  @Accessors val String uri
  @Accessors val Map<String, String> initData
  @Accessors val Map<String, Object> store = new ConcurrentHashMap<String, Object>
  
  @Accessors var () => void onClose
  
  override getId() { return ch.id.asShortText }
  
  override send(MSG msg) {
    if (state.get === State.CLOSED) {
      //Channel can send messages when in TRY state, to be able to send signals.
      srv.pipe.fail(new RuntimeException('Try to send MSG. Channel in CLOSED!'))
      return
    }
    
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
      srv.pipe.fail(ex)
    }
  }
  
  override close() {
    logger.debug("Channel({}) -> CLOSE", id)
    if (ch.open) ch.close
    
    state.set(State.CLOSED)
    srv.channels.remove(id)
    onClose?.apply
  }
  
  package new(WebSocketServer<MSG> srv, Channel ch, String uri) {
    this.srv = srv
    this.ch = ch
    this.uri = uri
    
    
    val decoder = new QueryStringDecoder(uri)
    val dataList = decoder.parameters.get('data')
    val data = if (!dataList.empty) {
      val base64Data = dataList.get(0)
      val stringData = new String(Base64.decoder.decode(base64Data))
      srv.initDataDecoder.apply(stringData)
    } else {
      Collections.EMPTY_MAP
    }
    
    this.initData = Collections.unmodifiableMap(data)
    
    logger.debug("Channel({}) -> OPEN", id)
  }
  
  package def void confirmOpen() {
    if (state.get !== State.CLOSED)
      state.set(State.READY)
  }
  
  package def nextFrame(WebSocketFrame frame) {
    if (state.get !== State.READY) {
      srv.pipe.fail(new RuntimeException('Try to process Frame. Channel in not READY!'))
      return
    }
    
    try {
      if (frame instanceof TextWebSocketFrame) {
        sb.append(frame.text)
        
        if (frame.finalFragment) {
          val txt = sb.toString
          sb.length = 0
          
          
            logger.debug("Channel({}) -> RCV-MSG: {}", id, txt)
            val msg = srv.decoder.apply(txt)
            srv.pipe.process(this, msg)
        }
      } else //BinaryWebSocketFrame
        throw new UnsupportedOperationException('''Unsupported frame type: «frame.class.name»''')
    } catch(Throwable ex) {
      srv.pipe.fail(ex)
    }
  }
}