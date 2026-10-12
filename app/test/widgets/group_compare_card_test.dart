import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/l10n/app_localizations.dart';
import 'package:qio_app/services/history_metrics.dart';
import 'package:qio_app/services/metrics_trend.dart';
import 'package:qio_app/services/queue_analytics.dart';
import 'package:qio_app/models/queue_feedback.dart';
import 'package:qio_app/widgets/comparison_table.dart';
import 'package:qio_app/widgets/group_compare_card.dart';

Widget wrap(Widget child) => MaterialApp(
  locale: const Locale('pt'),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  testWidgets('empty list renders only the title', (tester) async {
    await tester.pumpWidget(wrap(const GroupCompareSection(rows: [])));
    expect(find.text('Comparativo entre filas do grupo'), findsOneWidget);
    expect(find.byType(ComparisonTable), findsNothing);
  });

  const caixa = QueueComparison(
    queueId: 'a',
    name: 'Caixa',
    metrics: HistoryMetrics(
      total: 4,
      served: 3,
      noShow: 1,
      left: 0,
      noShowRate: 0.25,
      avgWaitMin: 7,
    ),
    feedback: FeedbackSummary(count: 2, average: 4.5),
    waitStats: WaitStats(
      samples: 6,
      medianMin: 6,
      p90Min: 12,
      bucketCounts: [0, 0, 0, 0],
    ),
    deltas: {
      MetricKey.total: Delta(abs: 2, pct: 100),
      MetricKey.avgWait: Delta(abs: -1, pct: -12),
    },
  );
  const balcao = QueueComparison(
    queueId: 'b',
    name: 'Balcão',
    metrics: HistoryMetrics(
      total: 9,
      served: 9,
      noShow: 0,
      left: 0,
      noShowRate: 0,
      avgWaitMin: 3,
    ),
    feedback: FeedbackSummary(count: 0),
    partial: true,
  );
  const vazia = QueueComparison(
    queueId: 'c',
    name: 'Vazia',
    metrics: HistoryMetrics(
      total: 0,
      served: 0,
      noShow: 0,
      left: 0,
      noShowRate: 0,
    ),
    feedback: FeedbackSummary(count: 0),
  );

  List<String> order(WidgetTester tester) {
    final names = ['Caixa', 'Balcão', 'Vazia'];
    final ys = {
      for (final n in names)
        if (find.text(n).evaluate().isNotEmpty)
          n: tester.getTopLeft(find.text(n)).dy,
    };
    return ys.keys.toList()..sort((x, y) => ys[x]!.compareTo(ys[y]!));
  }

  testWidgets('renders one row per queue with its numbers', (tester) async {
    await tester.pumpWidget(
      wrap(const GroupCompareSection(rows: [caixa, vazia])),
    );
    expect(find.text('Caixa'), findsOneWidget);
    expect(find.text('Vazia'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('7 min'), findsOneWidget);
    expect(find.text('6 min'), findsOneWidget);
    expect(find.text('12 min'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(find.text('4.5 ★'), findsOneWidget);
    expect(find.text('▲ 100%'), findsOneWidget);
    expect(find.text('▼ 12%'), findsOneWidget);
  });

  testWidgets('headers show the columns and the active sort', (tester) async {
    await tester.pumpWidget(
      wrap(const GroupCompareSection(rows: [caixa, balcao])),
    );
    for (final h in ['Fila', 'Atend.', 'Espera', 'Mediana', 'P90', 'Nota']) {
      expect(find.text(h), findsOneWidget);
    }
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    expect(order(tester), ['Balcão', 'Caixa']);
  });

  testWidgets('tapping a header sorts and a second tap reverses', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const GroupCompareSection(rows: [caixa, balcao, vazia])),
    );
    expect(order(tester), ['Balcão', 'Caixa', 'Vazia']);
    await tester.tap(find.byKey(const ValueKey('cmp-sort-wait')));
    await tester.pump();
    expect(order(tester), ['Balcão', 'Caixa', 'Vazia']);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cmp-sort-wait')));
    await tester.pump();
    expect(order(tester), ['Caixa', 'Balcão', 'Vazia']);
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('cmp-sort-served')));
    await tester.pump();
    expect(order(tester), ['Balcão', 'Caixa', 'Vazia']);
    await tester.tap(find.byKey(const ValueKey('cmp-sort-rating')));
    await tester.pump();
    expect(order(tester), ['Caixa', 'Balcão', 'Vazia']);
  });

  testWidgets('no-show sort puts rows without data last', (tester) async {
    await tester.pumpWidget(
      wrap(const GroupCompareSection(rows: [vazia, caixa, balcao])),
    );
    await tester.tap(find.byKey(const ValueKey('cmp-sort-noShow')));
    await tester.pump();
    expect(order(tester), ['Balcão', 'Caixa', 'Vazia']);
  });

  testWidgets('partial rows are flagged and show no variation', (tester) async {
    await tester.pumpWidget(wrap(const GroupCompareSection(rows: [balcao])));
    expect(find.text('dados parciais'), findsOneWidget);
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('each row has a full spoken label and headers are buttons', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(wrap(const GroupCompareSection(rows: [caixa])));
    expect(
      find.bySemanticsLabel(RegExp(r'^Caixa\. 4 atendimentos · espera 7 min')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp('Mediana 6 min, P90 12 min')),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        RegExp('Atendimentos subiu 100% vs. período anterior'),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(RegExp(r'Ordenar por Atendimentos, ordem decr')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('scrolls horizontally on a narrow screen without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await tester.pumpWidget(
      wrap(const GroupCompareSection(rows: [caixa, balcao])),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsWidgets);
  });
}
