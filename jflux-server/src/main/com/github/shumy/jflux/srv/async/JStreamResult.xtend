package com.github.shumy.jflux.srv.async

import com.fasterxml.jackson.databind.ObjectMapper
import com.github.shumy.jflux.api.IStreamResult
import com.github.shumy.jflux.msg.JError
import com.github.shumy.jflux.msg.JMessage
import com.github.shumy.jflux.pipeline.PContext
import java.util.UUID
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class JStreamResult implements IStreamResult<Object> {
  public val String suid = 'str:' + UUID.randomUUID.toString
  
  val msgId = new AtomicLong(0L)
  val mapper = new ObjectMapper
  val PContext<JMessage> ctx
  
  val onCancel = new AtomicReference<()=>void>
  val isComplete = new AtomicBoolean(false)
  
  def void cancel() {
    if (!isComplete.get) {
      isComplete.set = true
      onCancel.get?.apply
    }
  }
  
  override onCancel(()=>void onCancel) {
    this.onCancel.set = onCancel
  }
  
  override next(Object data) {
    if (!isComplete.get) {
      val value = mapper.valueToTree(data)
      ctx.send(JMessage.publishData(msgId.incrementAndGet, suid, value))
    }
  }
  
  override error(Throwable error) {
    if (!isComplete.get) {
      isComplete.set = true
      ctx.send(JMessage.publishError(msgId.incrementAndGet, suid, new JError(500, error.message)))
      ctx.channel.store.remove(suid)
    }
  }
  
  override complete() {
    if (!isComplete.get) {
      isComplete.set = true
      ctx.send(JMessage.streamComplete(msgId.incrementAndGet, suid))
      ctx.channel.store.remove(suid)
    }
  }
}