package com.github.shumy.jflux.test

import org.osgi.service.component.annotations.Activate
import org.osgi.service.component.annotations.Component
import org.osgi.service.component.annotations.Deactivate
import org.osgi.service.component.annotations.Reference
import com.github.shumy.jflux.api.store.IServiceStore

@Component
class BundleStarter {
  @Reference IServiceStore store
  
  @Activate
  def void start() {
    store => [
      addService('Hello', new HelloService)
    ]
  }
  
  @Deactivate
  def void stop() {
    store => [
      removeService('Hello')
    ]
  }
}