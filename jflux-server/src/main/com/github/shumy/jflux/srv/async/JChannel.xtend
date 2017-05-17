package com.github.shumy.jflux.srv.async

import com.fasterxml.jackson.databind.JsonNode
import com.fasterxml.jackson.databind.ObjectMapper
import com.github.shumy.jflux.api.IChannel
import com.github.shumy.jflux.api.ISubscription
import com.github.shumy.jflux.msg.JMessage
import com.github.shumy.jflux.pipeline.PChannel
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicLong
import org.eclipse.xtend.lib.annotations.FinalFieldsConstructor
import org.eclipse.xtend.lib.annotations.Accessors

@FinalFieldsConstructor
class JChannel implements IChannel<Object> {
  package val localSubs = new ConcurrentHashMap<String, JSubscription>
  package val clientSubs = new ConcurrentHashMap<String, JChannelSubscription>
  
  package var (ISubscription<Object>)=>void onSubscribe = null
  package var (ISubscription<Object>)=>void onCancel = null
  
  val mapper = new ObjectMapper
  @Accessors val Class<?> msgType
  
  override publish(Object data) {
    localSubs.values.forEach[ ch | ch.publish(data) ]
    
    if (!clientSubs.empty) {
      val tree = mapper.valueToTree(data)
      clientSubs.values.forEach[ ch | ch.channelPublish(tree) ]
    }
  }
  
  override onSubscribe((ISubscription<Object>)=>void onSubscribe) {
    this.onSubscribe = onSubscribe
  }
  
  override onCancel((ISubscription<Object>)=>void onCancel) {
    this.onCancel = onCancel
  }
  
  override get(String suid) {
    val sub = localSubs.get(suid)
    if (sub === null)
      return clientSubs.get(suid)
  }
  
  override subscribe((Object)=>void onData) {
    val suid = 'ch:' + UUID.randomUUID.toString
    val sub = new JSubscription(this, suid, onData)
    localSubs.put(suid, sub)
    
    onSubscribe?.apply(sub)
    return sub
  }
  
  def void channelPublish(JsonNode tree) {
    clientSubs.values.forEach[ ch | ch.channelPublish(tree) ]
    
    if (!localSubs.empty) {
      val data = mapper.treeToValue(tree, msgType)
      localSubs.values.forEach[ ch | ch.publish(data) ]
    }
  }
  
  def JChannelSubscription channelSubscribe(Long msgId, PChannel<JMessage> pCh) {
    val suid = 'ch:' + UUID.randomUUID.toString
    val sub = new JChannelSubscription(this, suid, pCh, mapper)
    clientSubs.put(suid, sub)
    
    pCh.send(JMessage.subscribeReply(msgId, suid))
    onSubscribe?.apply(sub)
    return sub
  }
}

@FinalFieldsConstructor
class JChannelSubscription implements ISubscription<Object> {
  val msgId = new AtomicLong(0L)
  
  val JChannel ch
  val String suid
  val PChannel<JMessage> pCh
  val ObjectMapper mapper
  
  override suid() { suid }
  
  override publish(Object data) {
    val tree = mapper.valueToTree(data)
    pCh.send(JMessage.publishData(msgId.incrementAndGet, suid, tree))
  }
  
  override cancel() {
    ch.clientSubs.remove(suid)
    ch.onCancel?.apply(this)
  }
  
  def void channelPublish(JsonNode data) {
    pCh.send(JMessage.publishData(msgId.incrementAndGet, suid, data))
  }
}

@FinalFieldsConstructor
class JSubscription implements ISubscription<Object> {
  val JChannel ch
  val String suid
  val (Object)=>void onData
  
  override suid() { suid }
  
  override publish(Object data) {
    onData.apply(data)
  }
  
  override cancel() {
    ch.localSubs.remove(suid)
    ch.onCancel?.apply(this)
  }
}