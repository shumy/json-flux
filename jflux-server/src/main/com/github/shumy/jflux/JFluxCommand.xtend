package com.github.shumy.jflux

import com.github.shumy.jflux.srv.ServiceStore
import org.osgi.service.component.annotations.Component
import picocli.CommandLine
import picocli.CommandLine.Command
import picocli.CommandLine.Option

// picocli docs at http://picocli.info/
@Component(service = JFluxCommand, property = #[
  'osgi.command.scope=jflux',
  'osgi.command.function=srv'
])
class JFluxCommand {
  
  def void srv(String ...args) throws Exception {
    val cmd = CommandLine.parse(new Service, args)
    
    if (cmd.help) {
      CommandLine.usage(new Service, System.out)
      return
    }
    
    if (cmd.srv !== null) { 
      ServiceStore.INSTANCE.printService(cmd.srv)
      return
    }
    
    ServiceStore.INSTANCE.printServices
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