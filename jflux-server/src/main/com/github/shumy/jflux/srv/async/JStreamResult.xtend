package com.github.shumy.jflux.srv.async

import com.fasterxml.jackson.databind.ObjectMapper
import com.github.shumy.jflux.api.IStreamResult
import com.github.shumy.jflux.msg.JError
import com.github.shumy.jflux.msg.JMessage
import com.github.shumy.jflux.pipeline.PContext
import java.util.UUID
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicReference

@FinalFieldsConstructor
class JStreamResult implements IStreamResult<Object> {
  public val String suid = UUID.randomUUID.toString
  
  val mapper = new ObjectMapper
  val PContext<JMessage> ctx
  
  val isComplete = new AtomicBoolean(false)
  val onCancel = new AtomicReference<()=>void>
  
  def void cancel() {
    if (!isComplete.get) {
      onCancel.get?.apply
      isComplete.set = true
    }
  }
  
  override onCancel(()=>void onCancel) {
    this.onCancel.set = onCancel
  }
  
  override next(Object data) {
    if (!isComplete.get) {
      val value = mapper.valueToTree(data)
      ctx.send(JMessage.publishData(ctx.msg.id, suid, value))
    }
  }
  
  override error(Throwable error) {
    if (!isComplete.get) {
      ctx.send(JMessage.publishError(ctx.msg.id, suid, new JError(500, error.message)))
      isComplete.set = true
    }
  }
  
  override complete() {
    if (!isComplete.get) {
      ctx.send(JMessage.streamComplete(ctx.msg.id, suid))
      isComplete.set = true
    }
  }
}