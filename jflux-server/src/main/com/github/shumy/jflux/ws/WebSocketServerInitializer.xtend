package com.github.shumy.jflux.ws

import io.netty.channel.Channel
import io.netty.channel.ChannelHandlerContext
import io.netty.channel.ChannelInitializer
import io.netty.channel.SimpleChannelInboundHandler
import io.netty.channel.socket.SocketChannel
import io.netty.handler.codec.http.HttpObjectAggregator
import io.netty.handler.codec.http.HttpServerCodec
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame
import io.netty.handler.codec.http.websocketx.WebSocketFrame
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
  
  val (Channel) => void onOpen
  val (String) => void onClose
  val (String, String) => void onMessage
  val (Throwable) => void onError
  
  override initChannel(SocketChannel ch) throws Exception {
    ch.pipeline => [
      if (sslCtx !== null)
        addLast(sslCtx.newHandler(ch.alloc))
      
      val wssph = new WebSocketServerProtocolHandler(wsPath, null, true, 64 * 1024, false, true) {
        /*override channelActive(ChannelHandlerContext ctx) throws Exception {
          super.channelActive(ctx)
          logger.debug("Channel open {}", ctx.channel.id.asShortText)
          onOpen.apply(ctx.channel)
        }*/
        
        /*override channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
          val req = msg as FullHttpRequest
          println(req.uri())
          
          super.channelRead(ctx, msg)
        }*/
        
        override userEventTriggered(ChannelHandlerContext ctx, Object evt) throws Exception {
          super.userEventTriggered(ctx, evt)
          if (evt instanceof HandshakeComplete) {
            logger.debug("Channel open {}", ctx.channel.id.asShortText)
            onOpen.apply(ctx.channel)
          }
        }
        
        override channelInactive(ChannelHandlerContext ctx) throws Exception {
          super.channelInactive(ctx)
          logger.debug("Channel close {}", ctx.channel.id.asShortText)
          onClose.apply(ctx.channel.id.asShortText)
        }
        
        override exceptionCaught(ChannelHandlerContext ctx, Throwable cause) throws Exception {
          super.exceptionCaught(ctx, cause)
          onError.apply(cause)
        }
      }
      
      val wsfh = new SimpleChannelInboundHandler<WebSocketFrame>() {
        override channelRead0(ChannelHandlerContext ctx, WebSocketFrame frame) throws Exception {
          if (frame instanceof TextWebSocketFrame) {
            val txtMsg = frame.text
            logger.debug("Channel {} message: {}", ctx.channel.id.asShortText, txtMsg)
            onMessage.apply(ctx.channel.id.asShortText, txtMsg)
          } else
            throw new UnsupportedOperationException('''Unsupported frame type: «frame.class.name»''')
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