import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_feedback.dart';
import 'package:qio_app/services/history_metrics.dart';
import 'package:qio_app/services/metrics_trend.dart';
import 'package:qio_app/services/queue_analytics.dart';
import 'package:qio_app/widgets/group_overview_section.dart';

import '../helpers/pump_app.dart';

const g1 = GroupComparison(
  groupId: 'g1',
  name: 'Clínica',
  queueCount: 2,
  metrics: HistoryMetrics(
    total: 10,
    served: 8,
    noShow: 2,
    left: 0,
    noShowRate: 0.2,
    avgWaitMin: 9,
  ),
  feedback: FeedbackSummary(count: 3, average: 4.2),
  waitStats: WaitStats(
    samples: 8,
    medianMin: 8,
    p90Min: 20,
    bucketCounts: [0, 0, 0, 0],
  ),
  deltas: {
    MetricKey.total: Delta(abs: 4, pct: 66),
    MetricKey.noShowRate: Delta(abs: -3, pct: -10),
  },
);

const none = GroupComparison(
  groupId: null,
  name: '',
  queueCount: 1,
  metrics: HistoryMetrics(
    total: 10,
    served: 10,
    noShow: 0,
    left: 0,
    noShowRate: 0,
  ),
  feedback: FeedbackSummary(count: 0),
  partial: true,
);

void main() {
  testWidgets('lists groups, Sem grupo, counts and variation', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: GroupOverviewSection(rows: const [g1, none], onSelect: (_) {}),
        ),
      ),
    );
    expect(find.text('Por grupo'), findsOneWidget);
    expect(find.text('Clínica'), findsOneWidget);
    expect(find.text('Sem grupo'), findsOneWidget);
    expect(find.text('2 filas'), findsOneWidget);
    expect(find.text('1 fila'), findsOneWidget);
    expect(find.text('▲ 66%'), findsOneWidget);
    expect(find.text('▼ 3 p.p.'), findsOneWidget);
    expect(find.text('dados parciais'), findsOneWidget);
    expect(find.text('20 min'), findsOneWidget);
  });

  testWidgets('tapping a row reports the matching scope', (tester) async {
    final picked = <MetricsScope>[];
    await pumpApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: GroupOverviewSection(
            rows: const [g1, none],
            onSelect: picked.add,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('cmp-row-g1')));
    await tester.tap(find.byKey(const ValueKey('cmp-row-none')));
    expect(picked, [const MetricsScope.group('g1'), MetricsScope.ungrouped]);
  });

  testWidgets('rows are buttons with a tap hint and a spoken summary', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: GroupOverviewSection(rows: const [g1], onSelect: (_) {}),
        ),
      ),
    );
    final node = tester.getSemantics(
      find.bySemanticsLabel(RegExp(r'^Clínica\. 2 filas\. 10 atendimentos')),
    );
    expect(node.flagsCollection.isButton, isTrue);
    expect(node.label, contains('Atendimentos subiu 66%'));
    expect(node.label, contains('Não compareceram caiu 3 p.p.'));
    handle.dispose();
  });

  testWidgets('320 px with 2.0 text scale does not overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await pumpApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: GroupOverviewSection(rows: const [g1, none], onSelect: (_) {}),
        ),
      ),
      size: const Size(320, 800),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in dark English', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: GroupOverviewSection(rows: const [g1, none], onSelect: (_) {}),
        ),
      ),
      locale: const Locale('en'),
      themeMode: ThemeMode.dark,
    );
    expect(find.text('By group'), findsOneWidget);
    expect(find.text('No group'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
