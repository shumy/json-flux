package com.github.shumy.jflux.msg;

import com.fasterxml.jackson.annotation.JsonProperty;

public enum Command {
  @JsonProperty("snd") SEND,
  @JsonProperty("rpl") REPLY,
  @JsonProperty("pub") PUBLISH,
  
  @JsonProperty("signal") SIGNAL;
}
