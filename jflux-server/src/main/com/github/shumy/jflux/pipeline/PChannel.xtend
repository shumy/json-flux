package com.github.shumy.jflux.pipeline

import java.util.Map

interface PChannel<MSG> {
  def String getId()
  def String getUri()
  def Map<String, String> getInitData()
  
  def void send(MSG msg)
  def void link(Pipeline<MSG> pipe)
  def void close()
  
  def Map<String, Object> getStore()
}