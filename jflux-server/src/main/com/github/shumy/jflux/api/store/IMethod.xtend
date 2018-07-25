package com.github.shumy.jflux.api.store

import java.util.List

interface IMethod {
  enum Type { INIT, PUBLISH, REQUEST, STREAM }
  
  def Type getType()
  def String getName()
  
  def String getReturnType()
  def List<String> getParamTypes()
}