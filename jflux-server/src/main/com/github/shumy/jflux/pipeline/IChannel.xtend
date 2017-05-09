package com.github.shumy.jflux.pipeline

import java.util.Map

interface IChannel<MSG> {
  def String getId()
  def void send(MSG msg)
  def void link(Pipeline<MSG> pipe)
  def void close()
  
  def Map<String, Object> getStore()
}