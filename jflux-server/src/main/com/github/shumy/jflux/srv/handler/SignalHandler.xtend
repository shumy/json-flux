package com.github.shumy.jflux.srv.handler

import com.github.shumy.jflux.api.ICancel
import com.github.shumy.jflux.msg.Flag
import com.github.shumy.jflux.msg.JError
import com.github.shumy.jflux.msg.JMessage
import com.github.shumy.jflux.pipeline.PContext
import java.util.Map
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.slf4j.LoggerFactory

@FinalFieldsConstructor
class SignalHandler implements (PContext<JMessage>)=>void {
  static val logger = LoggerFactory.getLogger(SignalHandler)
  
  val (Map<String, String>)=>JError onTryOpen
  
  override apply(PContext<JMessage> it) {
    if (msg.flag === Flag.CLOSE) {
      logger.debug("Channel({}) -> SIGNAL-CLOSE", channel.id)
      channel.store.forEach[ key, obj |
        if (obj instanceof ICancel) {
          println('STORE-CANCEL: ' + key)
          obj.cancel
        }
      ]
    } else if (msg.flag === Flag.OPEN) {
      logger.debug("Channel({}) -> SIGNAL-TRY-OPEN: ", channel.id, channel.initData)
      val reason = onTryOpen.apply(channel.initData)
      if (reason !== null) {
        channel.send(JMessage.signalRejected(reason))
        channel.close
        logger.debug("Channel({}) -> SIGNAL-OPEN-REJECTED", channel.id)
        return
      }
      
      logger.debug("Channel({}) -> SIGNAL-OPEN", channel.id)
    }
    
    //Signals traverse the pipeline. Maybe another handler need to process a CLOSE signal.
    next
  }
}