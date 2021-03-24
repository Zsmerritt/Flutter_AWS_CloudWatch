import 'dart:async';

/// A promise class adapted from js for use with the SimpleLock
class Promise<T> {
  bool active = true;
  late Completer completer;
  Promise() {
    this.completer = new Completer<T>();
  }

  /// return false if this promise is no longer active
  bool resolve(T val) {
    if (this.active) {
      this.completer.complete(val);
      this.active = false;
      return true;
    }
    return false;
  }

  /// cancel this promise
  void cancel() {
    if (this.active) {
      this.active = false;
    }
  }

  Future<T?> get future {
    return this.completer.future as Future<T?>;
  }
}
