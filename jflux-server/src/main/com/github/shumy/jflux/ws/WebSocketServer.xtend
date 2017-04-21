package com.github.shumy.jflux.ws

import io.netty.bootstrap.ServerBootstrap
import io.netty.channel.Channel
import io.netty.channel.EventLoopGroup
import io.netty.channel.nio.NioEventLoopGroup
import io.netty.channel.socket.nio.NioServerSocketChannel
import io.netty.handler.ssl.SslContext
import io.netty.handler.ssl.SslContextBuilder
import io.netty.handler.ssl.util.SelfSignedCertificate
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicReference
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.slf4j.LoggerFactory

@FinalFieldsConstructor
class WebSocketServer {
  static val logger = LoggerFactory.getLogger(WebSocketServer)
  
  val boolean ssl
  val int port
  val String path
  val (WsChannel) => void onOpen
  
  val ch = new AtomicReference<Channel>
  package val channels = new ConcurrentHashMap<String, WsChannel>
  
  def void start() throws Exception {
    new Thread[
      Thread.currentThread.name = "WebSocketServer-Thread"
      
      val SslContext sslCtx = if (ssl) {
        val ssc = new SelfSignedCertificate
        SslContextBuilder.forServer(ssc.certificate, ssc.privateKey).build
      }
      
      val bossGroup = new NioEventLoopGroup(1) as EventLoopGroup
      val workerGroup = new NioEventLoopGroup() as EventLoopGroup
      try {
        val b = new ServerBootstrap => [
          group(bossGroup, workerGroup)
          channel(NioServerSocketChannel)
          //handler(new LoggingHandler(LogLevel.DEBUG))
          childHandler(new WebSocketServerInitializer(path, sslCtx, [
            //on channel open
            val wsch = new WsChannel(this, it)
            channels.put(wsch.id, wsch)
            onOpen.apply(wsch)
          ], [
            //on channel close
            val wsch = channels.get(it)
            wsch.close
          ], [ id, frame |
            //on channel frame
            val wsch = channels.get(id)
            wsch.nextFrame(frame)
          ], [ error |
            //on channel error
            error.printStackTrace
          ]))
        ]
        
        ch.set(b.bind(port).sync.channel)
        logger.info('WebSocketServer available at {}', '''«IF ssl»wss«ELSE»ws«ENDIF»://127.0.0.1:«port»«path»''')
        ch.get.closeFuture.sync
        logger.info('WebSocketServer stopped')
        
      } finally {
        bossGroup.shutdownGracefully
        workerGroup.shutdownGracefully
      }
    ].start
  }
  
  def void stop() {
    ch.get?.close
  }
}