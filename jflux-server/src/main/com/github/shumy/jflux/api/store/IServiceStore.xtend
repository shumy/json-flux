package com.github.shumy.jflux.api.store

import com.github.shumy.jflux.api.Doc
import com.github.shumy.jflux.api.IChannel
import com.github.shumy.jflux.api.ISubscription
import java.util.List
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor

@FinalFieldsConstructor
class ServiceDesc {
  public val String name
  public val Doc doc
  
  public val List<ChannelDesc> channels
  public val List<MethodDesc> methods
}

@FinalFieldsConstructor
class ChannelDesc {
  public val String name
  public val String msgType
  public val Doc doc
}

@FinalFieldsConstructor
class MethodDesc {
  public val String name
  public val String modelType
  public val Doc doc
  
  public val String returnType
  public val List<ParamDesc> params
}

@FinalFieldsConstructor
class ParamDesc {
  public val String name
  public val String type
  public val Doc doc
}

interface IServiceStore {
  def List<ServiceDesc> getServices()
  def ServiceDesc getService(String name)
  
  def void addService(Object srv)
  def void addService(String srvName, Object srv)
  def void removeService(String srvName)
  
  def ISubscription onAdd((ServiceDesc)=>void onAdd)
  def ISubscription onRemove((String)=>void onRemove)
  
  def IMethod getMethod(String srvName, String methName)
  def <T> IChannel<T> getChannel(String srvName, String chlName)
}