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
  
  package var (ISubscription)=>void onSubscribe = null
  package var (ISubscription)=>void onCancel = null
  
  val mapper = new ObjectMapper
  @Accessors val Class<?> msgType
  
  override publish(Object data) {
    localSubs.values.forEach[ ch | ch.publish(data) ]
    
    if (!clientSubs.empty) {
      val tree = mapper.valueToTree(data)
      clientSubs.values.forEach[ ch | ch.channelPublish(tree) ]
    }
  }
  
  override onSubscribe((ISubscription)=>void onSubscribe) {
    this.onSubscribe = onSubscribe
  }
  
  override onCancel((ISubscription)=>void onCancel) {
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
class JChannelSubscription implements ISubscription {
  val msgId = new AtomicLong(0L)
  
  val JChannel ch
  val String suid
  val PChannel<JMessage> pCh
  val ObjectMapper mapper
  
  override suid() { suid }
  
  override cancel() {
    ch.clientSubs.remove(suid)
    ch.onCancel?.apply(this)
  }
  
  def void channelPublish(JsonNode data) {
    pCh.send(JMessage.publishData(msgId.incrementAndGet, suid, data))
  }
  
  def void publish(Object data) {
    val tree = mapper.valueToTree(data)
    pCh.send(JMessage.publishData(msgId.incrementAndGet, suid, tree))
  }
}

@FinalFieldsConstructor
class JSubscription implements ISubscription {
  val JChannel ch
  val String suid
  val (Object)=>void onData
  
  override suid() { suid }
  
  override cancel() {
    ch.localSubs.remove(suid)
    ch.onCancel?.apply(this)
  }
  
  def void publish(Object data) {
    onData.apply(data)
  }
}