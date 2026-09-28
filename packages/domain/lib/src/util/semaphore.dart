import 'dart:async';

/// 并发信号量 —— 聚合搜索/健康度探测的并发上限（docs/05 §8：信号量 8）。
class Semaphore {
  int _count;
  final _waiters = <Completer<void>>[];

  Semaphore(this._count);

  Future<void> acquire() {
    if (_count > 0) {
      _count--;
      return Future.value();
    }
    final waiter = Completer<void>();
    _waiters.add(waiter);
    return waiter.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _count++;
    }
  }
}
