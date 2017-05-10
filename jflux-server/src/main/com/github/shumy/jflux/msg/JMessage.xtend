package com.github.shumy.jflux.msg

import com.fasterxml.jackson.annotation.JsonCreator
import com.fasterxml.jackson.databind.JsonNode
import com.fasterxml.jackson.annotation.JsonProperty
import com.fasterxml.jackson.annotation.JsonInclude
import com.fasterxml.jackson.annotation.JsonInclude.Include

class JError {
  public val Integer code //use html codes
  public val String msg
  
  @JsonCreator new(
    @JsonProperty("code") Integer code,
    @JsonProperty("msg") String msg
  ) {
    this.code = code
    this.msg = msg
  }
  
  override toString() '''{code:«code», msg:«msg»}'''
}

@JsonInclude(Include.NON_NULL)
class JMessage {
  public val Long     id
  public val Command  cmd
  public val Flag     flag
  
  public val String   suid
  public val String   path
  
  public val JError   error
  public val JsonNode data
  
  @JsonCreator new(
    @JsonProperty("id") Long id,
    @JsonProperty("cmd") Command cmd,
    @JsonProperty("flag") Flag flag,
    @JsonProperty("suid") String suid,
    @JsonProperty("path") String path,
    @JsonProperty("error") JError error,
    @JsonProperty("data") JsonNode data
  ) {
    this.id = id
    this.cmd = cmd
    this.flag = flag
    
    this.suid = suid
    this.path = path
    
    this.error = error
    this.data = data
  }
  
  static def replyError(Long id, JError error) {
    new JMessage(id, Command.REPLY, Flag.ERROR, null, null, error, null)
  }
  
  static def publishData(Long id, String suid, JsonNode data) {
    new JMessage(id, Command.PUBLISH, null, suid, null, null, data)
  }

  static def publishError(Long id, String suid, JError error) {
    new JMessage(id, Command.PUBLISH, Flag.ERROR, suid, null, error, null)
  }
  
  static def publishCancel(Long id, String suid) {
    new JMessage(id, Command.PUBLISH, Flag.CANCEL, suid, null, null, null)
  }
  
  // (request/reply) OK
  static def requestReply(Long id, JsonNode data) {
    new JMessage(id, Command.REPLY, null, null, null, null, data)
  }
  
  // (request/stream) SUBSCRIBE
  static def streamReply(Long id, String suid) {
    new JMessage(id, Command.REPLY, Flag.SUBSCRIBE, suid, null, null, null)
  }
  
  // (request/stream) COMPLETE
  static def streamComplete(Long id, String suid) {
    new JMessage(id, Command.PUBLISH, Flag.COMPLETE, suid, null, null, null)
  }
  
  // (subscribe/channel)
  static def subscribeReply(Long id, String suid, JsonNode data) {
    new JMessage(id, Command.REPLY, null, suid, null, null, data)
  }
  
  // (SIGNAL, OPEN)
  static def signalOpen() {
    new JMessage(0L, Command.SIGNAL, Flag.OPEN, null, null, null, null)
  }
  
  // (SIGNAL, CLOSE)
  static def signalClose() {
    new JMessage(0L, Command.SIGNAL, Flag.CLOSE, null, null, null, null)
  }
  
  override toString() '''{id:«id», cmd:«cmd», flag:«flag», suid:«suid», path:«path», error:«error», data:«data»}'''
}