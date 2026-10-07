import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/l10n/app_localizations.dart';
import 'package:qio_app/services/metrics_trend.dart';
import 'package:qio_app/widgets/trend_chart.dart';

Widget host(List<DayPoint> series) => MaterialApp(
  locale: const Locale('pt'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SingleChildScrollView(child: TrendChart(series: series)),
  ),
);

DayPoint point(int day, int total, {double? wait, int noShow = 0}) => DayPoint(
  day: DateTime(2026, 10, day),
  total: total,
  served: total - noShow,
  noShow: noShow,
  noShowRate: total == 0 ? 0 : noShow / total,
  avgWaitMin: wait,
);

void main() {
  final series = [
    point(1, 2, wait: 5),
    point(2, 0),
    point(3, 4, wait: 8, noShow: 1),
  ];

  testWidgets('mostra resumo com média e dia de pico', (tester) async {
    await tester.pumpWidget(host(series));
    expect(find.text('Média de 2,0 por dia, pico em 03/10'), findsOneWidget);
    expect(find.text('Espera média'), findsWidgets);
    expect(find.text('Atendimentos'), findsOneWidget);
    expect(find.text('01/10'), findsOneWidget);
  });

  testWidgets('semantics expõe o resumo uma vez', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(series));
    await tester.pump();
    final tree = tester.getSemantics(find.byType(Scaffold)).toStringDeep();
    expect(
      RegExp('Média de 2,0 por dia, pico em 03/10').allMatches(tree).length,
      1,
    );
    handle.dispose();
  });

  testWidgets('alterna entre espera e no-show', (tester) async {
    await tester.pumpWidget(host(series));
    await tester.tap(find.text('Não comparecimento'));
    await tester.pump();
    expect(find.text('Não comparecimento'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('série sem atendimentos mostra aviso e não quebra', (
    tester,
  ) async {
    await tester.pumpWidget(host([point(1, 0), point(2, 0)]));
    expect(find.text('Sem dados no período'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('um único dia', (tester) async {
    await tester.pumpWidget(host([point(5, 3, wait: 4)]));
    expect(find.text('Média de 3,0 por dia, pico em 05/10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('trendStats', () {
    final s = trendStats(series);
    expect(s.avg, 2);
    expect(s.peak!.day, DateTime(2026, 10, 3));
    expect(trendStats(const []).peak, isNull);
    expect(trendStats([point(1, 0)]).peak, isNull);
  });
}
