package com.github.shumy.jflux.pipeline

interface IChannel<MSG> {
  def String getId()
  def void send(MSG msg)
  def void close()
}