package com.github.shumy.jflux.api.store

import com.github.shumy.jflux.api.IChannel
import java.util.List
import java.util.Map

interface IServiceStore {
  def List<String> getServices()
  def Map<String, Object> getPaths(String srv)
  
  def void addService(Object srv)
  def void addService(String srvName, Object srv)
  def void removeService(String srvName)
  
  def IMethod getMethod(String srvName, String methName)
  def <T> IChannel<T> getChannel(String srvName, String methName)
}