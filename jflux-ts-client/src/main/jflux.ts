import { WsChannel }  from './ws-channel';
import { Observable } from 'rxjs/Observable';
import { Subscriber } from 'rxjs/Subscriber';

class CMD {
  static readonly SEND      = 'snd'
  static readonly REPLY     = 'rpl'
  static readonly PUBLISH   = 'pub'

  static readonly SIGNAL    = 'sig'
}

class FLAG {
  static readonly SUBSCRIBE = 'sub'
  static readonly COMPLETE  = 'cpl'
  static readonly CANCEL    = 'cnl'
  static readonly ERROR     = 'err'

  //for signal messages...
  static readonly REJECTED  = 'rejected'
}

export interface JError {
  code: number
  msg: string
}

export class JFlux {
  static url: string
  static onError: (error: JError) => void

  static client(data: object): JFluxClient {
    return new JFluxClient(this.url, data)
  }
}

export class JFluxClient {
  readonly TIMEOUT = 5000

  private ws?: WsChannel

  private idCounter = 0
  private replyHandlers: { [key: number]: (msg: any)=>void } = {}
  private subscriptions: { [sui: string]: Subscriber<any> } = {}

  constructor(server: string, data: object) {
    let dataB64 = btoa(JSON.stringify(data))

    this.ws = new WsChannel(server + '?data=' + dataB64, _ => this.onMessage(_))
    this.ws.onError = _ => this.onError(_)
    this.ws.connect()

    /*TODO: how to handle small/big disconnections ?
     * ws.onClose -> clean replyHandlers/subscribers and fire error ?
     * fire error when detected a message sequence fail (1, 2, ..., 5) or after some timeout ?
     */
  }

  //TODO: return services info?
  //get paths(): Promise<TreeInfo>

  // (fire-and-forget)
  publish(path: string, data?: any): void {
    if (this.ws == null) {
      this.onError({ "code": 500, "msg": 'JFluxClient is closed'})
      return
    }

    this.ws.send({ "cmd": CMD.PUBLISH, "path": path, "data": data })
  }

  // (request/reply)
  request(path: string, data?: any): Promise<any> {
    if (this.ws == null) {
      this.onError({ "code": 500, "msg": 'JFluxClient is closed'})
      return
    }

    this.idCounter++
    let ID = this.idCounter

    return new Promise<any>((resolve, reject) => {
      this.replyHandlers[ID] = (msg) => {
        if (msg.flag == FLAG.ERROR) {
          reject(msg.error)
          return
        }
        
        if (msg.flag != null) {
          reject({ "code": 400, "msg": 'Unexpected response for (request/reply) with flag: ' + msg.flag })
          return
        }
        
        resolve(msg.data)
      }

      this.ws.send({ "id": ID, "cmd": CMD.SEND, "path": path, "data": data })
      setTimeout(_ => this.onReply({ "id": ID, "cmd": CMD.REPLY, "error": { "code": 408, "msg": '(request/reply) timeout!' } }), this.TIMEOUT)
    })
  }

  // (request/stream)
  stream(path: string, data?: any): Observable<any> {
    if (this.ws == null) {
      this.onError({ "code": 500, "msg": 'JFluxClient is closed'})
      return
    }

    this.idCounter++
    let ID = this.idCounter

    return new Observable<any>((sub) => {
      let SUID: string = null
      this.replyHandlers[ID] = (msg) => {
        if (msg.flag == FLAG.ERROR) {
          sub.error(msg.error)
          return
        }

        if (msg.flag != FLAG.SUBSCRIBE) {
          sub.error({ "code": 500, "msg": 'Unexpected response for (request/stream) with flag: ' + msg.flag })
          return
        }

        if (msg.suid == null) {
          sub.error({ "code": 500, "msg": 'Unexpected response for (request/stream) with no (suid)' })
          return
        }
        
        SUID = msg.suid
        this.subscriptions[SUID] = sub
      }

      this.ws.send({ "id": ID, "cmd": CMD.SEND, "path": path, "data": data })
      setTimeout(_ => this.onReply({ "id": ID, "cmd": CMD.REPLY, "error": { "code": 408, "msg": '(request/stream) timeout!' } }), this.TIMEOUT)

      //TeardownLogic -> cancel and unregister subscription
      return () => {
        if (SUID != null && this.subscriptions[SUID] != null) {
          this.ws.send({ "cmd": CMD.PUBLISH, "flag": FLAG.CANCEL, "suid": SUID })
          delete this.subscriptions[SUID]
        }
      }
    })
  }
  
  // (subscribe/channel)
  channel(path: string): Observable<any> {
    if (this.ws == null) {
      this.onError({ "code": 500, "msg": 'JFluxClient is closed'})
      return
    }

    this.idCounter++
    let ID = this.idCounter

    return new Observable<any>((sub) => {
      let SUID: string = null
      this.replyHandlers[ID] = (msg) => {
        if (msg.flag == FLAG.ERROR) {
          sub.error(msg.error)
          return
        }

        if (msg.flag != null) {
          sub.error({ "code": 500, "msg": 'Unexpected response for (subscribe/channel) with flag: ' + msg.flag })
          return
        }

        if (msg.suid == null) {
          sub.error({ "code": 500, "msg": 'Unexpected response for (subscribe/channel) with no (suid)' })
          return
        }
        
        SUID = msg.suid
        this.subscriptions[SUID] = sub
      }

      this.ws.send({ "id": ID, "cmd": CMD.SEND, "flag": FLAG.SUBSCRIBE, "path": path })
      setTimeout(_ => this.onReply({ "id": ID, "cmd": CMD.REPLY, "error": { "code": 408, "msg": '(request/stream) timeout!' } }), this.TIMEOUT)

      return () => {
        if (SUID != null && this.subscriptions[SUID] != null) {
          this.ws.send({ "cmd": CMD.PUBLISH, "flag": FLAG.CANCEL, "suid": SUID })
          delete this.subscriptions[SUID]
        }
      }
    })
  }

  close() {
    if (this.ws != null) {
      this.ws.disconnect()
      this.ws = null
    }
  }

  private onMessage(msg: any): void {
    if (msg.id == null) {
      if (msg.flag == FLAG.ERROR)
        this.onError(msg.error)
      else
        this.onError({ "code": 500, "msg": 'Unexpected message with no (id)' })
      return
    }

    if (msg.cmd == CMD.REPLY)
      this.onReply(msg)
    else if (msg.cmd == CMD.PUBLISH)
      this.onPublish(msg)
    else if (msg.cmd == CMD.SIGNAL)
      this.onSignal(msg)
    else  
      this.onError({ "code": 500, "msg": 'Unexpected message with cmd: ' + msg.cmd })

  }

  private onReply(msg: any): void {
    let handler = this.replyHandlers[msg.id]
    if (handler != null) {
      delete this.replyHandlers[msg.id]
      handler(msg)
    }
  }

  private onPublish(msg: any): void {
    if (msg.suid == null)
      this.onError({ "code": 500, "msg": 'Unexpected publish with no (suid)' })

    let sub = this.subscriptions[msg.suid]
    if (sub == null) {
      this.onError({ "code": 500, "msg": 'No subscription for suid: ' + msg.suid })
      return
    }

    if (msg.flag == null) {
      sub.next(msg.data)
    } else if (msg.flag == FLAG.COMPLETE || msg.flag == FLAG.CANCEL) {
      delete this.subscriptions[msg.suid]
      sub.complete()
    } else if (msg.flag == FLAG.ERROR) {
      delete this.subscriptions[msg.suid]
      sub.error(msg.error)
    }
  }

  private onSignal(msg: any) {
    if (msg.flag == FLAG.REJECTED) {
      this.ws.disconnect()
      this.onError(msg.error)
    }
  }

  private onError(error: JError): void {
    if (JFlux.onError != null)
      JFlux.onError(error)
    else
      console.error(error)
  }
}