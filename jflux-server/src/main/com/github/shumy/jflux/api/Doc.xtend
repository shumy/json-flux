package com.github.shumy.jflux.api

import java.lang.annotation.Target
import java.lang.annotation.Retention

@Target(TYPE, METHOD, FIELD, PARAMETER)
@Retention(RUNTIME)
annotation Doc {
  String value
}