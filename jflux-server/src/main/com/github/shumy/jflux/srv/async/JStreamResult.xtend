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
import java.util.Map

@FinalFieldsConstructor
class JStreamResult implements IStreamResult<Object> {
  public val String suid = UUID.randomUUID.toString
  
  val mapper = new ObjectMapper
  val Map<String, JStreamResult> streams
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
      ctx.send(JMessage.publishData(ctx.msg.id, suid, value))
    }
  }
  
  override error(Throwable error) {
    if (!isComplete.get) {
      isComplete.set = true
      ctx.send(JMessage.publishError(ctx.msg.id, suid, new JError(500, error.message)))
      streams.remove(suid)
    }
  }
  
  override complete() {
    if (!isComplete.get) {
      isComplete.set = true
      ctx.send(JMessage.streamComplete(ctx.msg.id, suid))
      streams.remove(suid)
    }
  }
}