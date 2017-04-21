package com.github.shumy.jflux.pipeline

interface IChannel {
  def String getId()
  def void send(String msg)
  def void close()
}