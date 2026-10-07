import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/analytics_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Recorder implements AnalyticsService {
  final calls = <String>[];

  @override
  Future<void> queueCreated(String queueId) async => calls.add('created');

  @override
  Future<void> entryCalled(String queueId) async => calls.add('called');

  @override
  Future<void> entryServed(String queueId) async => calls.add('served');
}

void main() {
  late List<bool> collection;
  late _Recorder recorder;

  AnalyticsController build({bool debug = false, bool emulators = false}) =>
      AnalyticsController(
        debug: debug,
        emulators: emulators,
        serviceFactory: () => recorder,
        setCollectionEnabled: (v) async => collection.add(v),
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    collection = [];
    recorder = _Recorder();
  });

  test('analyticsAllowed requires release, no emulators and no opt-out', () {
    expect(
      analyticsAllowed(debug: false, emulators: false, optedOut: false),
      isTrue,
    );
    expect(
      analyticsAllowed(debug: true, emulators: false, optedOut: false),
      isFalse,
    );
    expect(
      analyticsAllowed(debug: false, emulators: true, optedOut: false),
      isFalse,
    );
    expect(
      analyticsAllowed(debug: false, emulators: false, optedOut: true),
      isFalse,
    );
  });

  test('stays off in debug builds', () async {
    final c = build(debug: true);
    await c.load();
    expect(c.available, isFalse);
    expect(c.active, isFalse);
    expect(c.service, isA<NoopAnalytics>());
    expect(collection, [false]);
  });

  test('stays off with emulators', () async {
    final c = build(emulators: true);
    await c.load();
    expect(c.active, isFalse);
    expect(c.service, isA<NoopAnalytics>());
    expect(collection, [false]);
  });

  test('turns on in release by default', () async {
    final c = build();
    await c.load();
    expect(c.available, isTrue);
    expect(c.active, isTrue);
    expect(c.service, same(recorder));
    expect(collection, [true]);
  });

  test('opt-out persists and disables collection', () async {
    final c = build();
    await c.load();
    await c.setOptOut(true);
    expect(c.optedOut, isTrue);
    expect(c.service, isA<NoopAnalytics>());
    expect(collection.last, isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AnalyticsController.prefsKey), isTrue);

    final reloaded = build();
    await reloaded.load();
    expect(reloaded.optedOut, isTrue);
    expect(reloaded.active, isFalse);
  });

  test('opting back in re-enables', () async {
    SharedPreferences.setMockInitialValues({
      AnalyticsController.prefsKey: true,
    });
    final c = build();
    await c.load();
    expect(c.active, isFalse);
    await c.setOptOut(false);
    expect(c.active, isTrue);
    expect(collection.last, isTrue);
  });

  test('firebase service sends only queue_id', () async {
    final sent = <(String, Map<String, Object>)>[];
    final s = FirebaseAnalyticsService((n, p) async => sent.add((n, p)));
    await s.queueCreated('q1');
    await s.entryCalled('q1');
    await s.entryServed('q1');
    expect(sent.map((e) => e.$1), [
      'queue_created',
      'entry_called',
      'entry_served',
    ]);
    for (final e in sent) {
      expect(e.$2, {'queue_id': 'q1'});
    }
  });

  test('firebase service swallows sink errors', () async {
    final s = FirebaseAnalyticsService((n, p) async => throw Exception('x'));
    await s.queueCreated('q1');
  });
}
