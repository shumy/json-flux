package com.github.shumy.jflux.ws

import io.netty.channel.ChannelHandlerContext
import io.netty.channel.SimpleChannelInboundHandler
import io.netty.handler.codec.http.websocketx.TextWebSocketFrame
import io.netty.handler.codec.http.websocketx.WebSocketFrame
import java.util.Locale
import org.slf4j.LoggerFactory

class WebSocketFrameHandler extends SimpleChannelInboundHandler<WebSocketFrame> {
  static val logger = LoggerFactory.getLogger(WebSocketFrameHandler)
  
  override channelRead0(ChannelHandlerContext ctx, WebSocketFrame frame) throws Exception {
    if (frame instanceof TextWebSocketFrame) {
      val request = frame.text
      logger.info("{} received {}", ctx.channel.id, request)
      ctx.channel.writeAndFlush(new TextWebSocketFrame(request.toUpperCase(Locale.US)))
    } else
      throw new UnsupportedOperationException('''Unsupported frame type: «frame.class.name»''')
  }
}