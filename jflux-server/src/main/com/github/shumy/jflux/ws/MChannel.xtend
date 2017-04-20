package com.github.shumy.jflux.ws

import io.netty.channel.Channel
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtend.lib.annotations.Accessors
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame

@FinalFieldsConstructor
class MChannel {
  val Channel ch
  
  @Accessors var (String) => void onMessage //handled externally
  @Accessors var () => void onClose
  
  def getId() { return ch.id.asShortText }
  
  def void write(String msg) {
    ch.writeAndFlush(new TextWebSocketFrame(msg))
  }
  
  def void close() {
    if (ch.open) ch.close
    onClose?.apply
  }
}