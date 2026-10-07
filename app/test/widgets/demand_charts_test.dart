import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/l10n/app_localizations.dart';
import 'package:qio_app/services/metrics_export.dart';
import 'package:qio_app/services/history_metrics.dart';
import 'package:qio_app/services/queue_analytics.dart';
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

Widget host(MetricsReport report) => MaterialApp(
  locale: const Locale('pt'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  theme: QioTheme.light,
  home: Scaffold(
    body: SingleChildScrollView(child: DemandCharts(report: report)),
  ),
);

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
    final labels = <String>[];
    void walk(SemanticsNode n) {
      if (n.label.isNotEmpty) labels.add(n.label);
      n.visitChildren((c) {
        walk(c);
        return true;
      });
    }

    walk(tester.binding.pipelineOwner.semanticsOwner!.rootSemanticsNode!);
    expect(labels, contains('sex., 18h: 5 chegadas'));
    expect(labels, contains('seg., 09h: 1 chegada'));
    expect(labels.where((l) => RegExp(r', \d\dh: ').hasMatch(l)), hasLength(2));
    handle.dispose();
  });

  testWidgets('empty demand hides both cards', (tester) async {
    await tester.pumpWidget(host(reportWith(matrix())));
    expect(find.byType(Card), findsNothing);
  });
}
