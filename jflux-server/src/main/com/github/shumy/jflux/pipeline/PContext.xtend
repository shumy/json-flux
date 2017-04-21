package com.github.shumy.jflux.pipeline

import java.util.Iterator
import org.eclipse.xtend.lib.annotations.Accessors

class PContext {
  val Pipeline pipe
  val Iterator<(PContext)=>void> iter
  val IChannel channel
  
  @Accessors val PMessage msg
  
  boolean inFail = false
  
  package new(Pipeline pipe, Iterator<(PContext)=>void> iter, IChannel channel, PMessage msg) {
    this.pipe = pipe
    this.iter = iter
    this.channel = channel
    this.msg = msg
  }
  
  def void send(PMessage msg) {
    if(!inFail) {
      val txt = pipe.encoder.apply(msg)
      channel.send(txt)
    }
  }
  
  def void next() {
    if(!inFail && iter.hasNext) {
      try {
        iter.next.apply(this)
      } catch(RuntimeException ex) {
        ex.printStackTrace
        fail(ex)
      }
    }
  }
  
  def void fail(Throwable ex) {
    if(!inFail) {
      pipe.onFail?.apply(ex)
      inFail = true
    }
  }
}