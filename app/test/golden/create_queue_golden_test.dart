@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/screens/create_queue_screen.dart';
import 'package:qio_app/screens/queue_created_screen.dart';

import '../helpers/create_queue_flow.dart';
import '../helpers/fake_draft_store.dart';
import '../helpers/fake_services.dart';
import '../helpers/golden.dart';
import '../helpers/pump_app.dart';

Widget wizard() => CreateQueueScreen(
  queues: FakeQueueService(),
  groups: FakeGroupService(),
  draftStore: FakeCreateQueueDraftStore(),
  uid: 'uid-1',
);

Future<void> open(
  WidgetTester tester, {
  required ThemeMode mode,
  Size size = const Size(390, 844),
}) async {
  await pumpApp(tester, wizard(), themeMode: mode, size: size);
  await tester.pumpAndSettle();
}

Future<void> scheduleMode(WidgetTester tester) async {
  await typeName(tester, 'Clínica Sol');
  await tapKey(tester, 'create-continue');
  await tapKey(tester, 'create-mode-schedule');
  await tapKey(tester, 'create-suggest-30');
}

Widget created() => QueueCreatedScreen(
  queue: Queue(
    id: 'abc123',
    ownerId: 'uid-1',
    name: 'Clínica Sol',
    avgServiceMin: 10,
    createdAt: DateTime(2026, 10, 1),
  ),
  queues: FakeQueueService(),
  onShare: (_) async {},
  destinationBuilder: (context, target) => const Scaffold(),
);

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final tag = mode.name;

    testWidgets('wizard nome 390 $tag', (tester) async {
      await open(tester, mode: mode);
      await typeName(tester, 'Clínica Sol');
      await goldenExpect(tester, 'create_name_390_$tag');
    });

    testWidgets('wizard como entram 390 $tag', (tester) async {
      await open(tester, mode: mode);
      await scheduleMode(tester);
      await goldenExpect(tester, 'create_mode_390_$tag');
    });

    testWidgets('wizard alertas 390 $tag', (tester) async {
      await open(tester, mode: mode);
      await typeName(tester, 'Clínica Sol');
      await continueSteps(tester, 5);
      await tapKey(tester, 'alerts-enabled');
      await tapKey(tester, 'alerts-wait');
      await goldenExpect(tester, 'create_alerts_390_$tag');
    });

    testWidgets('wizard revisão 390 $tag', (tester) async {
      await open(tester, mode: mode);
      await scheduleMode(tester);
      await continueSteps(tester, 5);
      await goldenExpect(tester, 'create_review_390_$tag');
    });

    testWidgets('fila criada 390 $tag', (tester) async {
      await goldenApp(
        tester,
        created(),
        'create_created_390_$tag',
        themeMode: mode,
        size: const Size(390, 1000),
      );
    });
  }

  testWidgets('wizard revisão 320 light', (tester) async {
    await open(tester, mode: ThemeMode.light, size: const Size(320, 640));
    await scheduleMode(tester);
    await continueSteps(tester, 5);
    await goldenExpect(tester, 'create_review_320_light');
  });
}
