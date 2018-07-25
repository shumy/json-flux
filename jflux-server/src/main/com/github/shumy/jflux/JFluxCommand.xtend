package com.github.shumy.jflux

import com.github.shumy.jflux.api.store.IServiceStore
import org.osgi.service.component.annotations.Component
import org.osgi.service.component.annotations.Reference
import picocli.CommandLine
import picocli.CommandLine.Command
import picocli.CommandLine.Option

// picocli docs at http://picocli.info/
@Component(service = JFluxCommand, property = #[
  'osgi.command.scope=jflux',
  'osgi.command.function=srv'
])
class JFluxCommand {
  
  @Reference IServiceStore store
  
  def void srv(String ...args) throws Exception {
    val cmd = CommandLine.parse(new Service, args)
    
    if (cmd.help) {
      CommandLine.usage(new Service, System.out)
      return
    }
    
    if (cmd.srv !== null) {
      val srv = store.getService(cmd.srv)
      if (srv !== null) {
        println(srv.name)
        
        println('''  Channels:''')
        srv.channels.forEach[
          println('''    «name» -> (msgType: «msgType»)''')
        ]
        
        println('''  Methods:''')
        srv.methods.forEach[
          println('''    «name» -> (type: «modelType», params: [«FOR ptn: params SEPARATOR ','»«ptn.name»«ENDFOR»], return: «returnType»)''')
        ]
      }
      
      return
    }
    
    var n = 0
    for (srv: store.services) {
      n++
      println('''«n»: «srv»''')
    }
  }
}

@Command(
  name = 'srv',
  description = 'List all available JFLUX services, or details of a specified one.'
)
class Service {
  @Option(names = #['-h', '--help'], help = true, description = 'display this help message')
  public boolean help
  
  @Option(names = #['-s', '--service'], help = true, description = 'Service name.')
  public String srv
}