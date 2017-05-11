export class WsChannel {
  readonly RECONNECT_TIME = 3000
  readonly WAIT_TIME = 100

  private link: boolean = false
  private websocket: WebSocket

  onError?: (error: any) => void

  constructor(private url: string, private onMessage: (msg: any) => void) {}

  connect() {
    this.link = true
    this.tryConnect()
  }

  disconnect() {
    this.link = false
    if (this.websocket != null) {
      this.websocket.close()
      this.websocket = null
      console.log('WS-DISCONNECT: ', this.url)
    }
  }

  send(msg: any) {
    this.waitReady(() => {
      console.log('WS-SEND: ', msg)
      this.websocket.send(JSON.stringify(msg))
    })
  }

  private tryConnect() {
    if (this.link == false)
      return
     
    console.log('WS-TRY-CONNECT: ', this.url)
    this.websocket = new WebSocket(this.url)

    this.websocket.onopen = (evt) => {
      console.log('WS-CONNECT: ', this.url)
    }

    this.websocket.onclose = () => {
      this.websocket = null
      setTimeout(() => this.tryConnect(), this.RECONNECT_TIME)
    }

    this.websocket.onerror = (evt) => {
      console.log('WS-ERROR: ', evt)
      if (this.onError != null)
        this.onError(evt)
    }

    this.websocket.onmessage = (evt) => {
      let msg = JSON.parse(evt.data)
      console.log('WS-RECEIVED: ', msg)
      this.onMessage(msg)
    }
  }

  private waitReady(callback: () => void) {
    if (this.websocket != null && this.websocket.readyState == 1) {
      callback()
    } else {
      //console.log('WS-WAIT')
      setTimeout(() => this.waitReady(callback), this.WAIT_TIME)
    }
  }
}