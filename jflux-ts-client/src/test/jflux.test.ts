import { JFlux } from "../main/jflux";
import { expect } from "chai";

describe("JFlux Test", () => {
  JFlux.url = 'ws://127.0.0.1:8080/ws'
  let srvName = 'Hello'

  it("pub/sub", (done) => {
    let client = JFlux.client({test: 'test-(pub/sub)'})

    let n = 0
    let sub = client.channel('ch:' + srvName + ':chHello').subscribe(data => {
      n++
      if (n == 1) expect(data).to.equal('Init')
      if (n == 2) expect(data).to.equal('pubHello Micael')
      if (n == 3) {
        expect(data).to.equal('Jorge')
        sub.unsubscribe()
        client.close()
        done()
      }
    })

    client.publish('srv:' + srvName + ':pubHello', 'Micael')
    client.publish('ch:' + srvName + ':chHello', 'Jorge')
  })

  it("request/reply", (done) => {
    let client = JFlux.client({test: 'test-(request/reply)'})

    client.request('srv:' + srvName + ':simpleHello', 'Micael').then(res => {
      expect(res).to.equal('simpleHello Micael')
      client.close()
      done()
    })
  })

  it("request/stream", (done) => {
    let client = JFlux.client({test: 'test-(request/stream)'})

    let n = 0
    client.stream('srv:' + srvName + ':multipleHello', ['Micael', 'Alex', 'Pedro']).subscribe(data => {
        n++
        if (n == 1) expect(data).to.equal('multipleHello Micael')
        if (n == 2) expect(data).to.equal('multipleHello Alex')
        if (n == 3) expect(data).to.equal('multipleHello Pedro')
      }, _ => console.log(_), () => {
        client.close()
        done()
      })
  })

  it("request/stream-cancel", (done) => {
    let client = JFlux.client({test:'test-(request/stream-cancel)'})

    let sub = client.stream('srv:' + srvName + ':toCancelHello', ['Micael', 'Alex', 'Pedro']).subscribe(data => {
      expect(data).to.equal('toCancelHello Micael')
      sub.unsubscribe()
      client.close()
      done()
    })
  })
})