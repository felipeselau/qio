import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/l10n/app_localizations.dart';
import 'package:qio_app/services/metrics_trend.dart';
import 'package:qio_app/widgets/trend_chart.dart';

Widget host(
  List<DayPoint> series, {
  Locale locale = const Locale('pt'),
  double textScale = 1,
}) => MaterialApp(
  locale: locale,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(textScale)),
    child: child!,
  ),
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: TrendChart(series: series),
    ),
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
    expect(find.textContaining('Espera média'), findsOneWidget);
    expect(find.textContaining('Atendimentos por dia'), findsOneWidget);
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
    await tester.tap(find.text('No-show'));
    await tester.pump();
    expect(
      find.textContaining('Não comparecimento (máx. 25%)'),
      findsOneWidget,
    );
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

  testWidgets('legenda mostra o máximo das duas séries', (tester) async {
    await tester.pumpWidget(host(series));
    expect(find.text('Atendimentos por dia (máx. 4)'), findsOneWidget);
    expect(find.text('Espera média (máx. 8 min)'), findsOneWidget);
  });

  testWidgets('semântica tem um item por dia', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(host(series));
    await tester.pump();
    final tree = tester.getSemantics(find.byType(Scaffold)).toStringDeep();
    expect(tree, contains('01/10: 2 atendimentos, Espera 5 min'));
    expect(tree, contains('02/10: 0 atendimentos, Espera -'));
    expect(tree, contains('03/10: 4 atendimentos, Espera 8 min'));
    handle.dispose();
  });

  testWidgets('muitos dias não geram um item por dia nem erro', (tester) async {
    final handle = tester.ensureSemantics();
    final many = [for (var i = 0; i < 366; i++) point(1, i % 5, wait: 3)]
        .indexed
        .map(
          (e) => DayPoint(
            day: DateTime(2025, 10, 8 + e.$1),
            total: e.$2.total,
            served: e.$2.served,
            noShow: 0,
            noShowRate: 0,
            avgWaitMin: 3,
          ),
        )
        .toList();
    await tester.pumpWidget(host(many));
    await tester.pump();
    final tree = tester.getSemantics(find.byType(Scaffold)).toStringDeep();
    expect(tree, isNot(contains('atendimentos, Espera')));
    expect(tester.takeException(), isNull);
    handle.dispose();
  });

  for (final locale in ['pt', 'en', 'es']) {
    testWidgets('320px com textScaler 1.5 sem overflow em $locale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(series, locale: Locale(locale), textScale: 1.5),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('No-show'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }

  test('trendStats', () {
    final s = trendStats(series);
    expect(s.avg, 2);
    expect(s.peak!.day, DateTime(2026, 10, 3));
    expect(trendStats(const []).peak, isNull);
    expect(trendStats([point(1, 0)]).peak, isNull);
  });
}
