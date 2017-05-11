package com.github.shumy.jflux

import org.osgi.service.component.annotations.Component
import picocli.CommandLine.Option
import picocli.CommandLine
import picocli.CommandLine.Command

// picocli docs at http://picocli.info/
@Component(service = JFluxCommand, property = #[
  'osgi.command.scope=jflux',
  'osgi.command.function=calc',
  'osgi.command.function=eval'
])
class JFluxCommand {
  def void calc(String ...args) throws Exception {
    val cmd = CommandLine.parse(new Calc, args)
    if (cmd.help) {
      CommandLine.usage(new Calc, System.out)
      return
    }
    
    println('calc: ' + cmd.mode)
  }
  
  def void eval(String ...names) throws Exception {
    println('eval: ' + names)
  }
}

@Command(
  name = "calc",
  description = "Concatenate FILE(s), or standard input, to standard output."
)
class Calc {
  @Option(names = #['-h', '--help'], help = true, description = 'display this help message')
  public boolean help
  
  @Option(names = #['-m', '--mode'], help = true, required = true, description = 'Mode select.')
  public String mode
}