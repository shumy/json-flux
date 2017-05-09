import { JFlux } from "../main/jflux";
import { expect } from "chai";

describe("JFlux Test", () => {
  it("test connection", () => {
    JFlux.url = 'ws://127.0.0.1:8080/ws'
    let client = JFlux.client('token123456')

    /*let n = 0
    let tst = new Test()
    tst.testObservable().subscribe(
      (data) => { n = data },
      (error) => { console.log('Error: ', error) },
      () => { expect(n).to.equal(5) }
    )*/
  })
})