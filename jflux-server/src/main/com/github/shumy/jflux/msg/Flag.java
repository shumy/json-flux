package com.github.shumy.jflux.msg;

import com.fasterxml.jackson.annotation.JsonProperty;

public enum Flag {
    @JsonProperty("sub") SUBSCRIBE,
    @JsonProperty("cpl") COMPLETE,
    @JsonProperty("cnl") CANCEL,
    @JsonProperty("err") ERROR;
}
