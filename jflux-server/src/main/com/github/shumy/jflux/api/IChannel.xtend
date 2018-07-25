package com.github.shumy.jflux.api

interface IChannel<D> {
  def Class<?> getMsgType()
  def void publish(D data)
  
  def void onSubscribe((ISubscription)=>void onSubscribe)
  def void onCancel((ISubscription)=>void onCancel)
  
  def ISubscription get(String suid)
  def ISubscription subscribe((D)=>void onData)
}

interface ISubscription extends ICancel {
  def String suid()
}