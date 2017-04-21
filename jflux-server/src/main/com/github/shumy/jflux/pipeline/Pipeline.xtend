package com.github.shumy.jflux.pipeline

import java.util.ArrayList
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class Pipeline {
  package val (String) => PMessage decoder
  package val (PMessage) => String encoder
  val handlers = new ArrayList<(PContext)=>void>
  
  @Accessors(PUBLIC_SETTER) package var (Throwable) => void onFail
  
  def process(IChannel channel, String txt) {
    val msg = decoder.apply(txt)
    val ctx = new PContext(this, handlers.iterator, channel, msg)
    ctx.next
  }
  
  def handler((PContext)=>void handler) {
    handlers.add(handler)
  }
}