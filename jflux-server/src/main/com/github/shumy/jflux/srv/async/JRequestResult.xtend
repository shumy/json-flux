package com.github.shumy.jflux.srv.async

import com.fasterxml.jackson.databind.ObjectMapper
import com.github.shumy.jflux.api.IRequestResult
import com.github.shumy.jflux.msg.JError
import com.github.shumy.jflux.msg.JMessage
import com.github.shumy.jflux.pipeline.PContext
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import java.util.concurrent.atomic.AtomicBoolean

@FinalFieldsConstructor
class JRequestResult implements IRequestResult<Object> {
  val mapper = new ObjectMapper
  val PContext<JMessage> ctx
  
  val isComplete = new AtomicBoolean(false)
  
  override resolve(Object data) {
    if (!isComplete.get) {
      isComplete.set = true
      val value = mapper.valueToTree(data)
      ctx.send(JMessage.requestReply(ctx.msg.id, value))
    }
  }
  
  override reject(Throwable error) {
    if (!isComplete.get) {
      isComplete.set = true
      ctx.send(JMessage.replyError(ctx.msg.id, new JError(500, error.message)))
    }
  }
}