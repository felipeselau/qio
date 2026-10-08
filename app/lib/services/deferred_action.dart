import 'dart:async';

typedef DeferredTimerFactory =
    Timer Function(Duration delay, void Function() callback);

class DeferredActions<K> {
  DeferredActions({
    this.delay = const Duration(seconds: 5),
    DeferredTimerFactory? timerFactory,
  }) : _timerFactory = timerFactory ?? Timer.new;

  final Duration delay;
  final DeferredTimerFactory _timerFactory;
  final Map<K, _Pending> _pending = {};

  bool isPending(K key) => _pending.containsKey(key);

  Set<K> get pendingKeys => _pending.keys.toSet();

  bool schedule(K key, Future<void> Function() action) {
    if (_pending.containsKey(key)) return false;
    late final _Pending entry;
    final timer = _timerFactory(delay, () {
      if (_pending[key] != entry) return;
      _pending.remove(key);
      unawaited(action());
    });
    entry = _Pending(timer, action);
    _pending[key] = entry;
    return true;
  }

  bool cancel(K key) {
    final entry = _pending.remove(key);
    if (entry == null) return false;
    entry.timer.cancel();
    return true;
  }

  Future<void> flush(K key) async {
    final entry = _pending.remove(key);
    if (entry == null) return;
    entry.timer.cancel();
    await entry.action();
  }

  Future<void> flushAll() async {
    final keys = _pending.keys.toList();
    for (final key in keys) {
      await flush(key);
    }
  }
}

class _Pending {
  _Pending(this.timer, this.action);

  final Timer timer;
  final Future<void> Function() action;
}
