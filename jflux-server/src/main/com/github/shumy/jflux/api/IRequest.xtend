package com.github.shumy.jflux.api

interface IRequestResult<D> {
  def void resolve(D data)
  def void reject(Throwable error)
}

interface IRequest<D> extends (IRequestResult<D>)=>void {}