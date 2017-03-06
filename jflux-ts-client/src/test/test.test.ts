import { Test } from "../main/test";
import { expect } from "chai";

describe("testObservable", () => {
  it("should count to 5", () => {
    let n = 0
    let tst = new Test()
    tst.testObservable().subscribe(
      (data) => { n = data },
      (error) => { console.log('Error: ', error) },
      () => { expect(n).to.equal(5) }
    )
  })
})