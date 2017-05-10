import { JFlux } from "../main/jflux";
import { expect } from "chai";

describe("JFlux Test", () => {
  it("Server Integration Messages", (done) => {
    JFlux.url = 'ws://127.0.0.1:8080/ws'
    let client = JFlux.client('token123456')
    
    client.publish('srv:com.github.shumy.jflux.srv.HelloService:pubHello', 'Micael')
    
    client.request('srv:com.github.shumy.jflux.srv.HelloService:simpleHello', 'Micael')
      .then(res => {
        expect(res).to.equal('simpleHello Micael')
      })

    let n = 0
    client.stream('srv:com.github.shumy.jflux.srv.HelloService:multipleHello', ['Micael', 'Alex', 'Pedro'])
      .subscribe(data => {
        n++
        if (n == 1) expect(data).to.equal('multipleHello Micael')
        if (n == 2) expect(data).to.equal('multipleHello Alex')
        if (n == 3) expect(data).to.equal('multipleHello Pedro')
      })
  
    let sub = client.stream('srv:com.github.shumy.jflux.srv.HelloService:toCancelHello', ['Micael', 'Alex', 'Pedro'])
      .subscribe(data => {
        sub.unsubscribe()
        done()
      })
  })
})