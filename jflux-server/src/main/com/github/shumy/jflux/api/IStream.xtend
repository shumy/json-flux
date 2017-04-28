package com.github.shumy.jflux.api

interface IStreamResult<D> {
  def void onCancel(()=>void onCancel)
  def void next(D data)
  def void error(Throwable error)
  def void complete()
}

interface IStream<D> extends (IStreamResult<D>)=>void {}