package com.github.shumy.jflux.api

interface IChannel<D> {
  def void publish(D data)
  
  def ISubscription<D> get(String suid)
  def ISubscription<D> subscribe((D)=>void onData)
}

interface ISubscription<D> extends ICancel {
  def String suid()
  def void publish(D data)
}