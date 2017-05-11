package com.github.shumy.jflux.srv

import com.github.shumy.jflux.msg.JMessage
import com.github.shumy.jflux.pipeline.PContext
import com.github.shumy.jflux.msg.Flag
import com.github.shumy.jflux.api.ICancel

class SignalHandler implements (PContext<JMessage>)=>void {
  override apply(PContext<JMessage> it) {
    if (msg.flag === Flag.CLOSE) {
      println('SIGNAL-CLOSE: ' + channel.id)
      channel.store.forEach[ key, obj |
        if (obj instanceof ICancel) {
          println('SIGNAL-CANCEL: ' + key)
          obj.cancel
        }
      ]
    } else if (msg.flag === Flag.OPEN) {
      println('SIGNAL-OPEN: ' + channel.id)
    }
    
    //Signals traverse the pipeline. Maybe another handler need to process a CLOSE signal?
    next
  }
}