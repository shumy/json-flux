import { JFlux } from "../main/jflux";
import { expect } from "chai";

describe("JFlux Test", () => {
  let srvName = 'Hello'

  it("Server Integration Messages", (done) => {
    JFlux.url = 'ws://127.0.0.1:8080/ws'
    let client = JFlux.client('token123456')
    
    client.channel('ch:' + srvName + ':chHello')
      .subscribe(data => {
        console.log(data)
      })

    client.request('srv:' + srvName + ':simpleHello', 'Micael')
      .then(res => {
        expect(res).to.equal('simpleHello Micael')
      })

    let n = 0
    client.stream('srv:' + srvName + ':multipleHello', ['Micael', 'Alex', 'Pedro'])
      .subscribe(data => {
        n++
        if (n == 1) expect(data).to.equal('multipleHello Micael')
        if (n == 2) expect(data).to.equal('multipleHello Alex')
        if (n == 3) expect(data).to.equal('multipleHello Pedro')
      })
  
    let sub = client.stream('srv:' + srvName + ':toCancelHello', ['Micael', 'Alex', 'Pedro'])
      .subscribe(data => {
        sub.unsubscribe()
        done()
      })
    
    client.publish('srv:' + srvName + ':pubHello', 'Micael')
    client.publish('ch:' + srvName + ':chHello', 'Jorge')
  })
})