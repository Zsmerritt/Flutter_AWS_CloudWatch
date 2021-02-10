import 'dart:async';

class Promise<T> {
  bool active = true;
  Completer completer;
  Promise() {
    this.completer = new Completer<T>();
  }

  bool resolve(T val) {
    /// return false if this promise is no longer active
    if (this.active) {
      this.completer.complete(val);
      this.active = false;
      return true;
    }
    return false;
  }

  void cancel() {
    /// cancel this promise
    if (this.active) {
      this.active = false;
    }
  }

  Future<T> get future {
    return this.completer.future;
  }
}
