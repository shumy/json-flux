package com.github.shumy.jflux.msg

import com.fasterxml.jackson.databind.ObjectMapper
import com.github.shumy.jflux.msg.JMessage
import org.eclipse.xtend.lib.annotations.Accessors

class JMessageConverter {
  val mapper = new ObjectMapper
  @Accessors val (String) => JMessage decoder = [ mapper.readValue(it, JMessage) ]
  @Accessors val (JMessage) => String encoder = [ mapper.writeValueAsString(it) ]
}