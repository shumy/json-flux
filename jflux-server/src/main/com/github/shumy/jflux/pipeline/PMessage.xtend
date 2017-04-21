package com.github.shumy.jflux.pipeline

import com.fasterxml.jackson.annotation.JsonCreator
import com.fasterxml.jackson.databind.JsonNode
import com.fasterxml.jackson.annotation.JsonProperty

enum Command { SEND, REPLY, PUBLISH }
enum Flag { SUBSCRIBE, COMPLETE, CANCEL, ERROR }

class PMessage {
  public val Long     id
  public val Command  cmd
  public val Flag     flag
  
  public val String   suid
  public val String   path
  
  public val String   error
  public val JsonNode data
  
  @JsonCreator
  new(
    @JsonProperty("id") Long id,
    @JsonProperty("cmd") Command cmd,
    @JsonProperty("flag") Flag flag,
    @JsonProperty("suid") String suid,
    @JsonProperty("path") String path,
    @JsonProperty("error") String error,
    @JsonProperty("data") JsonNode data
  ) {
    this.id = id
    this.cmd = cmd
    this.flag = flag
    
    this.suid = suid
    this.path = path
    
    this.error = error
    this.data = data
    
    //TODO: apply some rules...
  }
  
  override toString() '''(id:«id», cmd:«cmd», flag:«flag», suid:«suid», path:«path», error:«error», data:«data»)'''
}