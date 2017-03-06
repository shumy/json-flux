import { Observable } from 'rxjs/Observable';
import 'rxjs/add/observable/of';

export class Test {
  testPromise(): Promise<String> {
    return new Promise<String>((resolve, reject) => {
      resolve('Test')
    })
  }

  testObservable(): Observable<number> {
    return Observable.of(1, 2, 3, 4, 5)
  }
}