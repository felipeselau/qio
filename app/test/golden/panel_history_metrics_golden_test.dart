@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_entry.dart';
import 'package:qio_app/models/queue_feedback.dart';
import 'package:qio_app/screens/history_screen.dart';
import 'package:qio_app/screens/metrics_screen.dart';
import 'package:qio_app/screens/queue_panel_screen.dart';
import 'package:qio_app/services/metrics_export.dart';

import '../helpers/fake_services.dart';
import '../helpers/golden.dart';

final fixedNow = DateTime(2025, 6, 15, 12);

Widget panel() => QueuePanelScreen(
  queueId: 'q1',
  queueName: 'Padaria',
  isOwner: true,
  queues: FakeQueueService(
    queues: {'q1': fakeQueue('q1', name: 'Padaria')},
    entries: {
      'q1': [
        fakeEntry('e1', 1, name: 'Ana', status: EntryStatus.called),
        fakeEntry('e2', 2, name: 'Bruno'),
        fakeEntry('e3', 3, name: 'Carla'),
        fakeEntry('e4', 4, name: 'Diego'),
      ],
    },
  ),
  operators: FakeOperatorService(),
  groups: FakeGroupService(),
  showTour: false,
);

Widget history() => HistoryScreen(
  queueId: 'q1',
  queueName: 'Padaria',
  queues: FakeQueueService(
    history: [
      fakeHistory(
        'h1',
        1,
        name: 'Ana',
        finishedAt: fixedNow.subtract(const Duration(minutes: 10)),
      ),
      fakeHistory(
        'h2',
        2,
        name: 'Bruno',
        result: 'no_show',
        finishedAt: fixedNow.subtract(const Duration(days: 3)),
      ),
      fakeHistory(
        'h3',
        3,
        name: 'Carla',
        result: 'left',
        finishedAt: fixedNow.subtract(const Duration(days: 40)),
      ),
    ],
    feedback: const [QueueFeedback(entryId: 'h1', rating: 5)],
  ),
  clock: () => fixedNow,
);

Future<List<QueueHistoryInput>> metricsData() async => [
  QueueHistoryInput(
    fakeQueue('a', name: 'Padaria'),
    [
      fakeHistory(
        'h1',
        1,
        finishedAt: fixedNow.subtract(const Duration(minutes: 5)),
      ),
      fakeHistory(
        'h2',
        2,
        finishedAt: fixedNow.subtract(const Duration(minutes: 20)),
      ),
      fakeHistory(
        'h3',
        3,
        result: 'no_show',
        finishedAt: fixedNow.subtract(const Duration(minutes: 30)),
      ),
      fakeHistory(
        'h4',
        4,
        finishedAt: fixedNow.subtract(const Duration(days: 2)),
      ),
      fakeHistory(
        'h5',
        5,
        finishedAt: fixedNow.subtract(const Duration(days: 5)),
      ),
      fakeHistory(
        'h6',
        6,
        finishedAt: fixedNow.subtract(const Duration(days: 20)),
      ),
    ],
    const [],
    const [],
  ),
  QueueHistoryInput(
    fakeQueue('b', name: 'Clinica'),
    const [],
    const [],
    const [],
  ),
];

Widget metrics() => MetricsScreen(loader: metricsData, clock: () => fixedNow);

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final tag = mode.name;

    testWidgets('panel 390 $tag', (tester) async {
      await goldenApp(
        tester,
        panel(),
        'panel_390_$tag',
        themeMode: mode,
        size: const Size(390, 844),
      );
    });

    testWidgets('history 390 $tag', (tester) async {
      await goldenApp(
        tester,
        history(),
        'history_390_$tag',
        themeMode: mode,
        size: const Size(390, 844),
      );
    });

    testWidgets('metrics 390 $tag', (tester) async {
      await goldenApp(
        tester,
        metrics(),
        'metrics_390_$tag',
        themeMode: mode,
        size: const Size(390, 1100),
      );
    });
  }
}
