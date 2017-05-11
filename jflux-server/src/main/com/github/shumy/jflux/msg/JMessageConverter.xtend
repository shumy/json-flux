package com.github.shumy.jflux.msg

import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.type.TypeFactory
import java.util.HashMap
import java.util.Map
import org.eclipse.xtend.lib.annotations.Accessors

class JMessageConverter {
  val factory = TypeFactory.defaultInstance
  val type = factory.constructMapType(HashMap, String, String)
  val mapper = new ObjectMapper
  
  @Accessors val (String) => Map<String, String> initDataDecoder = [ mapper.readValue(it, type) ]
  @Accessors val (String) => JMessage msgDecoder = [ mapper.readValue(it, JMessage) ]
  @Accessors val (JMessage) => String msgEncoder = [ mapper.writeValueAsString(it) ]
}