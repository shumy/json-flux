package com.github.shumy.jflux.test

import org.osgi.service.component.annotations.Activate
import org.osgi.service.component.annotations.Component
import org.osgi.service.component.annotations.Deactivate
import org.osgi.service.component.annotations.Reference
import com.github.shumy.jflux.api.store.IServiceStore
import org.slf4j.LoggerFactory

@Component
class BundleStarter {
  static val logger = LoggerFactory.getLogger(BundleStarter)
  
  @Reference IServiceStore store
  
  @Activate
  def void start() {
    logger.info('Starting bundle: JFlux-Test-Bundle')
    store => [
      addService('Hello', new HelloService)
    ]
  }
  
  @Deactivate
  def void stop() {
    logger.info('Stoping bundle: JFlux-Test-Bundle')
    store => [
      removeService('Hello')
    ]
  }
}