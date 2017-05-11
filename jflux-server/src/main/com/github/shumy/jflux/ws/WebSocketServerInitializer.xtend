package com.github.shumy.jflux.ws

import io.netty.channel.Channel
import io.netty.channel.ChannelHandlerContext
import io.netty.channel.ChannelInitializer
import io.netty.channel.SimpleChannelInboundHandler
import io.netty.channel.socket.SocketChannel
import io.netty.handler.codec.http.HttpObjectAggregator
import io.netty.handler.codec.http.HttpServerCodec
import io.netty.handler.codec.http.websocketx.WebSocketFrame
import io.netty.handler.codec.http.websocketx.WebSocketServerProtocolHandler
import io.netty.handler.codec.http.websocketx.extensions.compression.WebSocketServerCompressionHandler
import io.netty.handler.ssl.SslContext
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class WebSocketServerInitializer extends ChannelInitializer<SocketChannel> {
  val String wsPath
  val SslContext sslCtx
  
  val (Channel, String) => void onOpen
  val (String) => void onClose
  val (String, WebSocketFrame) => void onFrame
  val (Throwable) => void onError
  
  override initChannel(SocketChannel ch) throws Exception {
    ch.pipeline => [
      if (sslCtx !== null)
        addLast(sslCtx.newHandler(ch.alloc))
      
      val wssph = new WebSocketServerProtocolHandler(wsPath, null, true, 64 * 1024, false, true) {
        override userEventTriggered(ChannelHandlerContext ctx, Object evt) throws Exception {
          super.userEventTriggered(ctx, evt)
          if (evt instanceof HandshakeComplete) {
            onOpen.apply(ctx.channel, evt.requestUri)
          }
        }
        
        override channelInactive(ChannelHandlerContext ctx) throws Exception {
          super.channelInactive(ctx)
          onClose.apply(ctx.channel.id.asShortText)
        }
        
        override exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
          super.exceptionCaught(ctx, cause)
          onError.apply(cause)
        }
      }
      
      val wsfh = new SimpleChannelInboundHandler<WebSocketFrame>() {
        override channelRead0(ChannelHandlerContext ctx, WebSocketFrame frame) throws Exception {
          onFrame.apply(ctx.channel.id.asShortText, frame)
        }
      }
      
      addLast(new HttpServerCodec)
      addLast(new HttpObjectAggregator(64 * 1024))
      addLast(new WebSocketServerCompressionHandler)
      addLast(wssph)
      addLast(wsfh)
    ]
  }
}