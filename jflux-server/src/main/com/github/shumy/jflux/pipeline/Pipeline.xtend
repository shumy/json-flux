package com.github.shumy.jflux.pipeline

import java.util.ArrayList
import org.eclipse.xtend.lib.annotations.Accessors
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class Pipeline<MSG> {
  package val (String) => MSG decoder
  package val (MSG) => String encoder
  val handlers = new ArrayList<(PContext<MSG>)=>void>
  
  @Accessors(PUBLIC_SETTER) package var (Throwable) => void onFail
  
  def process(IChannel channel, String txt) {
    val msg = decoder.apply(txt)
    val ctx = new PContext<MSG>(this, handlers.iterator, channel, msg)
    ctx.next
  }
  
  def handler((PContext<MSG>)=>void handler) {
    handlers.add(handler)
  }
}