package com.github.shumy.jflux.api.store

import java.util.List

interface IMethod {
  enum Type { PUBLISH, REQUEST, STREAM }
  
  def Type getType()
  def String getName()
  
  def String getReturnTypeName()
  def List<String> getParameterTypesName()
}