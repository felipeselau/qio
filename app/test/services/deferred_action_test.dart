import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/deferred_action.dart';

class FakeTimer implements Timer {
  FakeTimer(this.callback);

  final void Function() callback;
  bool cancelled = false;
  bool fired = false;

  void fire() {
    if (cancelled) return;
    fired = true;
    callback();
  }

  @override
  void cancel() => cancelled = true;

  @override
  bool get isActive => !cancelled && !fired;

  @override
  int get tick => fired ? 1 : 0;
}

void main() {
  late List<FakeTimer> timers;
  late DeferredActions<String> actions;
  late List<String> ran;

  setUp(() {
    timers = [];
    ran = [];
    actions = DeferredActions<String>(
      timerFactory: (delay, cb) {
        final t = FakeTimer(cb);
        timers.add(t);
        return t;
      },
    );
  });

  Future<void> run(String id) async => ran.add(id);

  test('runs the action only when the timer fires', () {
    expect(actions.schedule('a', () => run('a')), isTrue);
    expect(actions.isPending('a'), isTrue);
    expect(ran, isEmpty);
    timers.single.fire();
    expect(ran, ['a']);
    expect(actions.isPending('a'), isFalse);
  });

  test('cancel prevents the action and frees the key', () {
    actions.schedule('a', () => run('a'));
    expect(actions.cancel('a'), isTrue);
    expect(timers.single.cancelled, isTrue);
    timers.single.fire();
    expect(ran, isEmpty);
    expect(actions.cancel('a'), isFalse);
    expect(actions.schedule('a', () => run('a')), isTrue);
  });

  test('rejects duplicate keys while pending', () {
    expect(actions.schedule('a', () => run('a')), isTrue);
    expect(actions.schedule('a', () => run('a')), isFalse);
    expect(timers, hasLength(1));
    expect(actions.pendingKeys, {'a'});
  });

  test('flush runs immediately and disarms the timer', () async {
    actions.schedule('a', () => run('a'));
    await actions.flush('a');
    expect(ran, ['a']);
    expect(timers.single.cancelled, isTrue);
    timers.single.fire();
    expect(ran, ['a']);
  });

  test('flushAll runs every pending action once', () async {
    actions.schedule('a', () => run('a'));
    actions.schedule('b', () => run('b'));
    await actions.flushAll();
    expect(ran, ['a', 'b']);
    expect(actions.pendingKeys, isEmpty);
  });

  test('uses the default 5 second delay', () {
    expect(DeferredActions<String>().delay, const Duration(seconds: 5));
  });

  test('cancelAll drops everything without running', () {
    actions.schedule('a', () => run('a'));
    actions.schedule('b', () => run('b'));
    actions.cancelAll();
    expect(actions.hasPending, isFalse);
    expect(timers.every((t) => t.cancelled), isTrue);
    expect(ran, isEmpty);
  });

  test('errors go to onError and do not block other flushes', () async {
    final errors = <Object>[];
    final guarded = DeferredActions<String>(
      timerFactory: (delay, cb) => FakeTimer(cb),
      onError: (e, st) => errors.add(e),
    );
    guarded.schedule('a', () async => throw StateError('boom'));
    guarded.schedule('b', () => run('b'));
    await guarded.flushAll();
    expect(errors, hasLength(1));
    expect(ran, ['b']);
  });

  test('schedule accepts a custom delay', () {
    Duration? used;
    final custom = DeferredActions<String>(
      timerFactory: (delay, cb) {
        used = delay;
        return FakeTimer(cb);
      },
    );
    custom.schedule('a', () => run('a'), delay: const Duration(seconds: 10));
    expect(used, const Duration(seconds: 10));
  });
}
