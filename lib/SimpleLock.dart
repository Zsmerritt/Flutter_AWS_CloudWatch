import 'dart:collection';

import 'Promise.dart';

/// A lock class to ensure that requests are made synchronously
class SimpleLock {
  late bool locked;
  late Queue<Promise> awaitingLock;
  final String name;
  SimpleLock({
    this.name = "<Unknown>",
  }) {
    this.awaitingLock = Queue();
    this.locked = false;
  }

  bool _acquireNoBlock() {
    // if available locks and returns true, else returns false
    if (!this.locked) {
      this.locked = true;
      return true;
    }
    return false;
  }

  Future<bool?> _acquire() async {
    /// ALWAYS release any lock ... or you will break everything!!!!!
    /// ALWAYS catch any exceptions in your code, and release the lock even if you get an exception
    if (this._acquireNoBlock()) {
      return true;
    }
    // return a future that will wait its turn
    Promise<bool> c = Promise<bool>();
    this.awaitingLock.add(c);
    return c.future;
  }

  void _release() {
    bool nextLockCompleted = false;
    while (!nextLockCompleted) {
      if (this.awaitingLock.isEmpty) {
        this.locked = false;
        return;
      }
      Promise nextLock = this.awaitingLock.removeFirst();
      nextLockCompleted = nextLock.resolve(true);
    }
  }

  /// Allows a function to run in a locked state to force
  /// synchronous calls.
  ///
  /// This is needed because AWS will reject cloudwatch calls
  /// if the sequence token is wrong
  Future<T> protect<T>(Function() f) async {
    // note ONLY PROTECTS to this lock!!!!
    await this._acquire();

    T result;
    try {
      var r = await f();
      result = r;
    } catch (e) {
      /// ALWAYS release an acquired lock!
      this._release();
      rethrow;
    }

    /// ALWAYS release an acquired lock!
    this._release();
    return result;
  }
}
