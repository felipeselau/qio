import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/l10n/app_localizations.dart';
import 'package:qio_app/services/metrics_trend.dart';
import 'package:qio_app/theme/qio_palette.dart';
import 'package:qio_app/widgets/delta_badge.dart';

Widget host(MetricKey key, Delta delta) => MaterialApp(
  locale: const Locale('pt'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: DeltaBadge(metric: key, delta: delta),
  ),
);

Color colorOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style!.color!;

void main() {
  testWidgets('total subindo é bom e mostra seta e texto', (tester) async {
    await tester.pumpWidget(
      host(MetricKey.total, const Delta(abs: 3, pct: 25)),
    );
    expect(find.text('▲ 25%'), findsOneWidget);
    expect(colorOf(tester, '▲ 25%'), QioPalette.light.statusOpenText);
  });

  testWidgets('total caindo é ruim', (tester) async {
    await tester.pumpWidget(
      host(MetricKey.total, const Delta(abs: -3, pct: -25)),
    );
    expect(find.text('▼ 25%'), findsOneWidget);
    expect(colorOf(tester, '▼ 25%'), QioPalette.light.statusClosedText);
  });

  testWidgets('espera subindo é ruim e caindo é bom', (tester) async {
    await tester.pumpWidget(
      host(MetricKey.avgWait, const Delta(abs: 2, pct: 40)),
    );
    expect(colorOf(tester, '▲ 40%'), QioPalette.light.statusClosedText);
    await tester.pumpWidget(
      host(MetricKey.avgWait, const Delta(abs: -2, pct: -40)),
    );
    expect(colorOf(tester, '▼ 40%'), QioPalette.light.statusOpenText);
  });

  testWidgets('no-show usa pontos percentuais e subir é ruim', (tester) async {
    await tester.pumpWidget(
      host(MetricKey.noShowRate, const Delta(abs: 5.2, pct: 30)),
    );
    expect(find.text('▲ 5 p.p.'), findsOneWidget);
    expect(colorOf(tester, '▲ 5 p.p.'), QioPalette.light.statusClosedText);
  });

  testWidgets('variação pequena mantém uma casa decimal', (tester) async {
    await tester.pumpWidget(
      host(MetricKey.avgWait, const Delta(abs: 0.1, pct: 0.3)),
    );
    expect(find.text('▲ 0,3%'), findsOneWidget);
  });

  testWidgets('zero exato é estável e neutro', (tester) async {
    await tester.pumpWidget(
      host(MetricKey.avgWait, const Delta(abs: 0, pct: 0)),
    );
    expect(find.text('= estável'), findsOneWidget);
    expect(colorOf(tester, '= estável'), QioPalette.light.textSecondary);
  });

  testWidgets('semântica descreve em palavras', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      host(MetricKey.avgWait, const Delta(abs: -2, pct: -40)),
    );
    expect(
      tester.getSemantics(find.byType(DeltaBadge)).label,
      'caiu 40% vs. período anterior',
    );
    handle.dispose();
  });
}
