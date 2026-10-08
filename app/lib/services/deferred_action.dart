import 'dart:async';

typedef DeferredTimerFactory =
    Timer Function(Duration delay, void Function() callback);

typedef DeferredErrorHandler = void Function(Object error, StackTrace stack);

class DeferredActions<K> {
  DeferredActions({
    this.delay = const Duration(seconds: 5),
    DeferredTimerFactory? timerFactory,
    this.onError,
  }) : _timerFactory = timerFactory ?? Timer.new;

  final Duration delay;
  final DeferredTimerFactory _timerFactory;
  final DeferredErrorHandler? onError;
  final Map<K, _Pending> _pending = {};

  bool get hasPending => _pending.isNotEmpty;

  bool isPending(K key) => _pending.containsKey(key);

  Set<K> get pendingKeys => _pending.keys.toSet();

  bool schedule(K key, Future<void> Function() action, {Duration? delay}) {
    if (_pending.containsKey(key)) return false;
    late final _Pending entry;
    final timer = _timerFactory(delay ?? this.delay, () {
      if (_pending[key] != entry) return;
      _pending.remove(key);
      unawaited(_run(action));
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

  void cancelAll() {
    for (final key in _pending.keys.toList()) {
      cancel(key);
    }
  }

  Future<void> flush(K key) async {
    final entry = _pending.remove(key);
    if (entry == null) return;
    entry.timer.cancel();
    await _run(entry.action);
  }

  Future<void> flushAll() async {
    final keys = _pending.keys.toList();
    for (final key in keys) {
      await flush(key);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e, st) {
      final handler = onError;
      if (handler == null) rethrow;
      handler(e, st);
    }
  }
}

class _Pending {
  _Pending(this.timer, this.action);

  final Timer timer;
  final Future<void> Function() action;
}
