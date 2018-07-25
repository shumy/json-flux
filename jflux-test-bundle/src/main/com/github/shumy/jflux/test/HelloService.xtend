package com.github.shumy.jflux.test

import com.github.shumy.jflux.api.Channel
import com.github.shumy.jflux.api.IChannel
import com.github.shumy.jflux.api.IRequest
import com.github.shumy.jflux.api.IStream
import com.github.shumy.jflux.api.Publish
import com.github.shumy.jflux.api.Request
import com.github.shumy.jflux.api.Service
import com.github.shumy.jflux.api.Stream
import com.github.shumy.jflux.api.Init
import com.github.shumy.jflux.api.Doc
import java.util.List

@Service
@Doc('A service with multiple compliment methods and channels.')
class HelloService {
  @Channel(String)
  @Doc('The compliment channel.')
  IChannel<String> chHello
  
  @Init
  def void initializer() {
    chHello.onSubscribe[ println('Init: ' + suid) ]
    chHello.onCancel[ println('Close: ' + suid) ]
    chHello.subscribe[
      println('''chHello («it»)''')
    ]
  }
  
  @Publish
  @Doc('Publish a compliment in the chHello channel.')
  def void pubHello(@Doc('The name to compliment.') String name) {
    chHello.publish('''pubHello «name»''')
  }
  
  @Request
  @Doc('A simple hello method, returning the compliment.')
  def String simpleHello(@Doc('The name to compliment.') String name)
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
      for(n: names)
        next('''multipleHello «n»''')
      complete
    ]
  }
  
  @Stream
  def IStream<String> toCancelHello(List<String> names) {
    return [
      onCancel[ println('toCancelHello -> CANCEL') ]
      
      for(n: names) {
        Thread.sleep(100)
        next('''toCancelHello «n»''')
      }
      complete
    ]
  }
}