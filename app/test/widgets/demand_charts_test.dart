import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/l10n/app_localizations.dart';
import 'package:qio_app/services/metrics_export.dart';
import 'package:qio_app/services/history_metrics.dart';
import 'package:qio_app/services/queue_analytics.dart';
import 'package:qio_app/theme/qio_colors.dart';
import 'package:qio_app/theme/qio_theme.dart';
import 'package:qio_app/widgets/demand_charts.dart';

MetricsReport reportWith(List<List<int>> matrix) => MetricsReport(
  period: HistoryPeriod.all,
  operatorQueueId: null,
  operatorQueueName: null,
  isEmpty: false,
  metrics: const HistoryMetrics(
    total: 0,
    served: 0,
    noShow: 0,
    left: 0,
    noShowRate: 0,
  ),
  distribution: const [],
  peaks: const [],
  ranking: const [],
  operators: const [],
  operatorNames: const {},
  truncated: false,
  historyLimit: 500,
  weekdays: [for (final r in matrix) r.fold(0, (a, b) => a + b)],
  heatmap: matrix,
  demandPeak: peakCell(matrix),
);

Widget host(
  MetricsReport report, {
  String locale = 'pt',
  double width = 800,
  double textScale = 1,
  TextDirection? direction,
}) => MaterialApp(
  locale: Locale(locale),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: QioTheme.light,
  builder: (context, c) => Directionality(
    textDirection: direction ?? Directionality.of(context),
    child: MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: c),
      ),
    ),
  ),
  home: Scaffold(
    body: SingleChildScrollView(child: DemandCharts(report: report)),
  ),
);

List<String> semanticLabels(WidgetTester tester) {
  final labels = <String>[];
  void walk(SemanticsNode n) {
    if (n.label.isNotEmpty) labels.add(n.label);
    n.visitChildren((c) {
      walk(c);
      return true;
    });
  }

  walk(
    tester
        .binding
        .rootElement!
        .renderObject!
        .owner!
        .semanticsOwner!
        .rootSemanticsNode!,
  );
  return labels;
}

double _lum(Color c) => c.computeLuminance();

double contrast(Color a, Color b) {
  final l1 = _lum(a), l2 = _lum(b);
  final hi = l1 > l2 ? l1 : l2, lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  List<List<int>> matrix() => [for (var d = 0; d < 7; d++) List.filled(24, 0)];

  testWidgets('heatmap exposes summary and one node per non-empty cell', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final m = matrix()
      ..[4][18] = 5
      ..[0][9] = 1;
    await tester.pumpWidget(host(reportWith(m)));

    expect(find.text('Pico: sex., 18h–19h'), findsOneWidget);
    expect(find.bySemanticsLabel('Pico: sex., 18h–19h'), findsOneWidget);
    final labels = semanticLabels(tester);
    expect(labels, contains('sex., 18h: 5 chegadas'));
    expect(labels, contains('seg., 09h: 1 chegada'));
    expect(labels.where((l) => RegExp(r', \d\dh: ').hasMatch(l)), hasLength(2));
    handle.dispose();
  });

  testWidgets('empty demand hides both cards', (tester) async {
    await tester.pumpWidget(host(reportWith(matrix())));
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('narrow width with large text does not overflow', (tester) async {
    final m = matrix()
      ..[4][18] = 5
      ..[0][9] = 1;
    for (final locale in ['pt', 'en', 'es']) {
      await tester.pumpWidget(
        host(reportWith(m), locale: locale, width: 320, textScale: 1.5),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('spanish labels, legend and weekday summary', (tester) async {
    final handle = tester.ensureSemantics();
    final m = matrix()
      ..[4][18] = 5
      ..[0][9] = 1;
    await tester.pumpWidget(host(reportWith(m), locale: 'es'));
    final labels = semanticLabels(tester);
    expect(labels, contains('Pico: vie, 18h–19h'));
    expect(labels, contains('vie, 18h: 5 llegadas'));
    expect(labels, contains('lun, 09h: 1 llegada'));
    expect(labels.any((l) => l.contains('lun: 1, mar: 0')), isTrue);
    expect(find.text('menos'), findsOneWidget);
    expect(find.text('más'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('cell semantics follow the ambient directionality', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final m = matrix()..[4][18] = 5;
    await tester.pumpWidget(host(reportWith(m), direction: TextDirection.rtl));
    SemanticsNode? cell;
    void walk(SemanticsNode n) {
      if (n.label == 'sex., 18h: 5 chegadas') cell = n;
      n.visitChildren((c) {
        walk(c);
        return true;
      });
    }

    walk(
      tester
          .binding
          .rootElement!
          .renderObject!
          .owner!
          .semanticsOwner!
          .rootSemanticsNode!,
    );
    expect(cell!.textDirection, TextDirection.rtl);
    handle.dispose();
  });

  test('heat levels are distinct from empty in both themes', () {
    expect(heatLevel(0, 10), 0);
    expect(heatLevel(1, 100), 1);
    expect(heatLevel(100, 100), 4);
    expect(
      [
        for (final c in [1, 30, 55, 80, 100]) heatLevel(c, 100),
      ],
      [1, 2, 3, 4, 4],
    );
    for (final b in [Brightness.light, Brightness.dark]) {
      QioColors.apply(b);
      final empty = QioColors.gray200;
      final colors = [for (var l = 0; l <= 4; l++) heatColor(l, empty)];
      expect(colors.toSet().length, 5);
      expect(contrast(colors[1], empty), greaterThan(1.3));
      for (var l = 2; l <= 4; l++) {
        expect(
          contrast(colors[l], empty),
          greaterThan(contrast(colors[l - 1], empty)),
        );
      }
    }
    QioColors.apply(Brightness.light);
  });
}
