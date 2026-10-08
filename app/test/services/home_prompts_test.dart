import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/home_prompts.dart';

void main() {
  late List<String> events;

  HomePrompts build({
    Future<void> Function()? tour,
    Duration timeout = const Duration(milliseconds: 30),
  }) => HomePrompts(
    runTour: tour ?? () async => events.add('tour'),
    shouldPromptPush: () async => true,
    askPush: () async => events.add('push'),
    canShowDialog: () => true,
    tourTimeout: timeout,
  );

  setUp(() => events = []);

  test(
    'completed tour on a later launch still allows the pending push',
    () async {
      final p = build(tour: () async {});
      await p.onQueues(hasOwned: true);
      expect(events, ['push']);
    },
  );

  test('a failing tour does not block or repeat, push still asked', () async {
    var runs = 0;
    final p = build(
      tour: () async {
        runs++;
        throw StateError('boom');
      },
    );
    await p.onQueues(hasOwned: true);
    await p.onQueues(hasOwned: true);
    expect(runs, 1);
    expect(events, ['push']);
  });

  test('a tour that never completes is released by the timeout', () async {
    final p = build(tour: () => Future<void>.delayed(const Duration(hours: 1)));
    await p.onQueues(hasOwned: true);
    expect(p.tourDone, isTrue);
    expect(events, ['push']);
  });

  test('tour is retried when the route was busy', () async {
    var free = false;
    final p = build();
    await p.onQueues(hasOwned: true, routeFree: () => free);
    expect(events, isEmpty);
    expect(p.tourDone, isFalse);
    free = true;
    await p.onQueues(hasOwned: true, routeFree: () => free);
    expect(events, ['tour', 'push']);
  });

  test('push is asked only once', () async {
    final p = build();
    await p.onQueues(hasOwned: true);
    await p.onQueues(hasOwned: true);
    expect(events, ['tour', 'push']);
  });
}
