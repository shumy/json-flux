package com.github.shumy.jflux.api

interface IChannel<D> {
  def Class<?> getMsgType()
  def void publish(D data)
  
  def void onSubscribe((ISubscription<D>)=>void onSubscribe)
  def void onCancel((ISubscription<D>)=>void onCancel)
  
  def ISubscription<D> get(String suid)
  def ISubscription<D> subscribe((D)=>void onData)
}

interface ISubscription<D> extends ICancel {
  def String suid()
  def void publish(D data)
}