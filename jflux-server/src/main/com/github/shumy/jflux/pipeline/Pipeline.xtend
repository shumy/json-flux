package com.github.shumy.jflux.pipeline

import java.util.ArrayList
import org.eclipse.xtend.lib.annotations.Accessors

class Pipeline<MSG> {
  val handlers = new ArrayList<(PContext<MSG>)=>void>
  
  @Accessors(PUBLIC_SETTER) package var (Throwable) => void onFail
  
  def process(PChannel<MSG> channel, MSG msg) {
    val ctx = new PContext<MSG>(this, handlers.iterator, channel, msg)
    ctx.next
  }
  
  def handler((PContext<MSG>)=>void handler) {
    handlers.add(handler)
  }
}