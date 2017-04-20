package com.github.shumy.jflux.ws

import io.netty.channel.ChannelHandlerContext
import io.netty.channel.ChannelInitializer
import io.netty.channel.socket.SocketChannel
import io.netty.handler.codec.http.HttpObjectAggregator
import io.netty.handler.codec.http.HttpServerCodec
import io.netty.handler.codec.http.websocketx.WebSocketServerProtocolHandler
import io.netty.handler.codec.http.websocketx.extensions.compression.WebSocketServerCompressionHandler
import io.netty.handler.ssl.SslContext
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.slf4j.LoggerFactory

@FinalFieldsConstructor
class WebSocketServerInitializer extends ChannelInitializer<SocketChannel> {
  static val logger = LoggerFactory.getLogger(WebSocketServerInitializer)
  
  val String wsPath
  val SslContext sslCtx
  
  override initChannel(SocketChannel ch) throws Exception {
    ch.pipeline => [
      if (sslCtx !== null)
        addLast(sslCtx.newHandler(ch.alloc))
      
      val wssph = new WebSocketServerProtocolHandler(wsPath, null, true, 64 * 1024, false, true) {
        
        override channelRegistered(ChannelHandlerContext ctx) throws Exception {
          super.channelRegistered(ctx)
          logger.info("Channel open {}", ctx.channel.id)
          
        }
        
        override channelUnregistered(ChannelHandlerContext ctx) throws Exception {
          super.channelUnregistered(ctx)
          logger.info("Channel closed {}", ctx.channel.id)
        }
        
      }
      
      addLast(new HttpServerCodec)
      addLast(new HttpObjectAggregator(64 * 1024))
      addLast(new WebSocketServerCompressionHandler)
      addLast(wssph)
      addLast(new WebSocketFrameHandler)
    ]
  }
}