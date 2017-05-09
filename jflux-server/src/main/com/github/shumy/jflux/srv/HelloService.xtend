package com.github.shumy.jflux.srv

import com.github.shumy.jflux.api.Channel
import com.github.shumy.jflux.api.IRequest
import com.github.shumy.jflux.api.IStream
import com.github.shumy.jflux.api.Publish
import com.github.shumy.jflux.api.Request
import com.github.shumy.jflux.api.Service
import com.github.shumy.jflux.api.Stream
import java.util.List

@Service
class HelloService {
  //@Channel val channel = new JChannel<String>
  
  @Publish
  def void pubHello(String name) {
    println('''pubHello «name»''')
    //channel.publish('''pubHello «name»''')
  }
  
  @Request
  def String simpleHello(String name)
    '''simpleHello «name»'''
  
  @Request
  def IRequest<String> oneHello(String name) {
    return [
      resolve('''oneHello «name»''')
    ]
  }
  
  @Stream
  def IStream<String> multipleHello(List<String> names) {
    return [
      onCancel[ println('multipleHello -> CANCEL') ]
      
      for(n: names) {
        Thread.sleep(1000)
        next('''multipleHello «n»''')
      }
      complete
    ]
  }
}