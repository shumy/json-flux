package com.github.shumy.jflux.pipeline

import java.util.Iterator
import org.eclipse.xtend.lib.annotations.Accessors

class PContext<MSG> {
  val Pipeline<MSG> pipe
  val Iterator<(PContext<MSG>)=>void> iter
  
  @Accessors val PChannel<MSG> channel
  @Accessors val MSG msg
  
  boolean inFail = false
  
  package new(Pipeline<MSG> pipe, Iterator<(PContext<MSG>)=>void> iter, PChannel<MSG> channel, MSG msg) {
    this.pipe = pipe
    this.iter = iter
    this.channel = channel
    this.msg = msg
  }
  
  def void send(MSG msg) {
    if(!inFail) {
      channel.send(msg)
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