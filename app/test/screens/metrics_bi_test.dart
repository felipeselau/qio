import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/l10n/app_localizations.dart';
import 'package:qio_app/screens/metrics_screen.dart';
import 'package:qio_app/services/abandonment_metrics.dart';
import 'package:qio_app/services/attendant_metrics.dart';
import 'package:qio_app/services/brand_palette.dart';
import 'package:qio_app/services/goal_metrics.dart';
import 'package:qio_app/services/staffing_metrics.dart';
import 'package:qio_app/services/operator_metrics.dart';
import 'package:qio_app/theme/qio_palette.dart';
import 'package:flutter/semantics.dart';
import '../helpers/fake_services.dart';
import 'package:qio_app/services/metrics_export.dart';
import 'package:qio_app/widgets/bi_info.dart';

import '../helpers/bi_data.dart';
import '../helpers/pump_app.dart';

const tall = Size(390, 7000);

Future<void> tick(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

Widget screen(List<QueueHistoryInput> data) =>
    MetricsScreen(loader: () async => data, clock: () => biNow);

String cell(WidgetTester tester, String id, String col) =>
    tester.widget<Text>(find.byKey(ValueKey('attendants-cell-$id-$col'))).data!;

Finder chip(String label) => find.widgetWithText(ChoiceChip, label);

Future<void> open(WidgetTester tester, List<QueueHistoryInput> data) async {
  await pumpApp(tester, screen(data), size: tall);
  await tick(tester);
}

void main() {
  group('atendentes', () {
    testWidgets('tabela mostra os valores esperados', (tester) async {
      await open(tester, biData(attendantEntries()));
      expect(find.byKey(const ValueKey('attendants-section')), findsOneWidget);
      expect(cell(tester, 'op1', 'served'), '4');
      expect(cell(tester, 'op1', 'service'), '5 min');
      expect(cell(tester, 'op1', 'deviation'), '-50%');
      expect(cell(tester, 'op1', 'rate'), '4.8/h');
      expect(cell(tester, 'op1', 'idle'), '60%');
      expect(cell(tester, 'op1', 'noShow'), '0');
      expect(cell(tester, 'op1', 'rating'), '—');
      expect(cell(tester, 'op2', 'service'), '15 min');
      expect(cell(tester, 'op2', 'deviation'), '+50%');
      expect(cell(tester, 'op2', 'rate'), '3.2/h');
      expect(cell(tester, 'op2', 'idle'), '20%');
      expect(cell(tester, 'op2', 'noShow'), '1');
      expect(find.text('Ana'), findsWidgets);
      expect(find.text('Bia'), findsWidgets);
    });

    testWidgets('operador sem amostra suficiente mostra traço', (tester) async {
      final one = biData([
        attendantEntries().first,
        ...attendantEntries().where((e) => e.id.startsWith('b')),
      ]);
      await open(tester, one);
      expect(cell(tester, 'op1', 'service'), '—');
      expect(cell(tester, 'op1', 'deviation'), '—');
      expect(cell(tester, 'op1', 'rate'), '—');
      expect(cell(tester, 'op1', 'idle'), '—');
    });

    testWidgets('ordenar pela coluna inverte a ordem', (tester) async {
      await open(tester, biData(attendantEntries()));
      double y(String id) =>
          tester.getTopLeft(find.byKey(ValueKey('attendants-row-$id'))).dy;
      expect(y('op1'), lessThan(y('op2')));
      await tester.tap(find.byKey(const ValueKey('attendants-sort-service')));
      await tick(tester);
      expect(y('op1'), lessThan(y('op2')));
      await tester.tap(find.byKey(const ValueKey('attendants-sort-service')));
      await tick(tester);
      expect(y('op2'), lessThan(y('op1')));
    });

    testWidgets('periodo muda os números', (tester) async {
      await open(tester, biData([...attendantEntries(), oldAttendantEntry()]));
      expect(cell(tester, 'op1', 'served'), '4');
      await tester.tap(chip('Tudo'));
      await tick(tester);
      expect(cell(tester, 'op1', 'served'), '5');
    });

    testWidgets('gráfico por hora, por turno e por atendente', (tester) async {
      await open(tester, biData(attendantEntries()));
      expect(
        find.byKey(const ValueKey('attendants-hour-bars')),
        findsOneWidget,
      );
      expect(find.text('Mais atendimentos: 12h (4)'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('attendants-mode-shift')));
      await tick(tester);
      expect(
        find.byKey(const ValueKey('attendants-shift-bars')),
        findsOneWidget,
      );
      expect(
        find.text('Mais atendimentos: Tarde (12h–18h) (8)'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('attendants-chart-operator')));
      await tick(tester);
      await tester.tap(find.text('Ana').last);
      await tick(tester);
      expect(
        find.text('Mais atendimentos: Tarde (12h–18h) (4)'),
        findsOneWidget,
      );
    });

    testWidgets('só não compareceu: gráfico vazio explica', (tester) async {
      final only = attendantEntries().where((e) => e.id == 'bn').toList();
      await open(tester, biData(only));
      await tester.tap(chip('Tudo'));
      await tick(tester);
      expect(
        find.byKey(const ValueKey('attendants-chart-empty')),
        findsOneWidget,
      );
    });

    testWidgets('sem atendentes mostra o estado vazio existente', (
      tester,
    ) async {
      await open(tester, biData(abandonEntries().take(0).toList()));
      expect(find.byKey(const ValueKey('attendants-section')), findsNothing);
    });

    testWidgets('botão i abre a ajuda com os quatro blocos', (tester) async {
      await open(tester, biData(attendantEntries()));
      final btn = find.byKey(const ValueKey('info-attendantRate'));
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tick(tester);
      expect(
        find.byKey(const ValueKey('info-sheet-attendantRate')),
        findsOneWidget,
      );
      for (final t in [
        'O que é',
        'Como é calculado',
        'Dados usados',
        'Para que serve',
      ]) {
        expect(find.text(t), findsOneWidget);
      }
      expect(find.textContaining('janela em que atuou no dia'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('info-close')));
      await tick(tester);
      expect(
        find.byKey(const ValueKey('info-sheet-attendantRate')),
        findsNothing,
      );
    });
  });

  group('desistências', () {
    testWidgets('faixas, inflexão, estimativa, hora e capacidade', (
      tester,
    ) async {
      await open(tester, biData(abandonEntries()));
      expect(find.byKey(const ValueKey('abandon-section')), findsOneWidget);
      Finder valueIn(String key) => find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(Text),
      );
      expect(
        tester
            .widgetList<Text>(valueIn('abandon-wait-20'))
            .map((t) => t.data)
            .toList(),
        ['20–40 min', '22%'],
      );
      expect(
        tester
            .widgetList<Text>(valueIn('abandon-wait-40'))
            .map((t) => t.data)
            .toList(),
        ['40+ min', '—'],
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('abandon-inflection')))
            .data,
        contains('20–40 min'),
      );
      expect(
        tester
            .widgetList<Text>(valueIn('abandon-estimate-10'))
            .map((t) => t.data)
            .toList(),
        ['10–20 min', '44%'],
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('estimate-accuracy-mean')))
            .data,
        contains('+3.5 min'),
      );
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('abandon-hour-peak')))
            .data,
        'Maior taxa às 11h: 44% (4 de 9)',
      );
      expect(find.text('Possível falta de capacidade'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('abandon-capacity-text')))
            .data,
        contains('11h'),
      );
    });

    testWidgets('sem estimativa gravada explica a limitação', (tester) async {
      await open(tester, biData(abandonEntries(estimates: false)));
      expect(
        find.byKey(const ValueKey('abandon-estimate-empty')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('estimate-accuracy-mean')),
        findsNothing,
      );
    });

    testWidgets('sem horário crítico mostra mensagem neutra', (tester) async {
      final calm = abandonEntries()
          .where((e) => e.id.startsWith('h9'))
          .toList();
      await open(tester, biData(calm));
      expect(find.text('Nenhum horário crítico no período'), findsOneWidget);
      expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('abandon-inflection')))
            .data,
        'Nenhuma faixa passa do limite de 20% a cada 10 min.',
      );
    });

    testWidgets('amostra insuficiente em tudo mostra estados vazios', (
      tester,
    ) async {
      await open(tester, biData(abandonEntries().take(2).toList()));
      expect(find.byKey(const ValueKey('abandon-wait-empty')), findsOneWidget);
      expect(find.byKey(const ValueKey('abandon-hour-empty')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('abandon-capacity-card')),
        findsOneWidget,
      );
    });

    testWidgets('botão i do sinal de capacidade abre a ajuda', (tester) async {
      await open(tester, biData(abandonEntries()));
      final btn = find.byKey(const ValueKey('info-capacitySignal'));
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tick(tester);
      expect(
        find.byKey(const ValueKey('info-sheet-capacitySignal')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Horas com espera média de 15 min ou mais'),
        findsOneWidget,
      );
    });

    testWidgets('todos os indicadores têm botão i', (tester) async {
      await pumpApp(
        tester,
        screen(
          biData([
            ...attendantEntries(),
            ...abandonEntries(),
            ...goalEntries(),
            ...planningEntries(),
          ], goals: biGoals),
        ),
        size: const Size(390, 16000),
      );
      await tick(tester);
      for (final i in BiIndicator.values) {
        if (i == BiIndicator.staffingObserved) continue;
        expect(
          find.byKey(ValueKey('info-${i.name}')),
          findsOneWidget,
          reason: i.name,
        );
      }
      await tester.tap(find.byKey(const ValueKey('staffing-mode-observed')));
      await tick(tester);
      expect(
        find.byKey(const ValueKey('info-staffingObserved')),
        findsOneWidget,
      );
    });
  });

  group('ajuda', () {
    for (final locale in const ['pt', 'en', 'es']) {
      testWidgets('todos os indicadores têm texto em $locale', (tester) async {
        await pumpApp(
          tester,
          Builder(
            builder: (context) => Scaffold(
              body: ListView(
                children: [
                  for (final i in BiIndicator.values)
                    () {
                      final t = biInfoTexts(AppLocalizations.of(context), i);
                      return Text(
                        '${t.name}|${t.what}|${t.how}|${t.data}|${t.use}',
                      );
                    }(),
                ],
              ),
            ),
          ),
          locale: Locale(locale),
          size: tall,
        );
        for (final w in tester.widgetList<Text>(find.byType(Text))) {
          expect(w.data!.split('|').every((p) => p.trim().isNotEmpty), isTrue);
        }
      });
    }
  });

  group('layout', () {
    for (final entry in {'320': 320.0, '390': 390.0}.entries) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('largura ${entry.key} texto ${scale}x sem overflow', (
          tester,
        ) async {
          await pumpApp(
            tester,
            Builder(
              builder: (context) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: screen(
                  biData([...attendantEntries(), ...abandonEntries()]),
                ),
              ),
            ),
            size: Size(entry.value, 9000),
          );
          await tick(tester);
          expect(find.byKey(const ValueKey('abandon-section')), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('inglês escuro 320', (tester) async {
      await pumpApp(
        tester,
        screen(biData([...attendantEntries(), ...abandonEntries()])),
        locale: const Locale('en'),
        themeMode: ThemeMode.dark,
        size: const Size(320, 7000),
      );
      await tick(tester);
      expect(find.text('Abandonment'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('revisão', () {
    List<QueueHistoryInput> twoQueues() => [
      QueueHistoryInput(
        fakeQueue('a', name: 'Padaria'),
        abandonEntries(),
        const [],
        const [],
      ),
      QueueHistoryInput(
        fakeQueue('b', name: 'Clinica'),
        [
          for (var k = 0; k < 5; k++)
            biEntry(
              'c$k',
              joined: DateTime.utc(2025, 6, 14, 12, k),
              called: DateTime.utc(2025, 6, 14, 12, k + 2),
              finished: DateTime.utc(2025, 6, 14, 12, k + 5),
            ),
        ],
        const [],
        const [],
      ),
    ];

    testWidgets('filtro de fila muda as barras de desistência', (tester) async {
      await open(tester, twoQueues());
      expect(find.byKey(const ValueKey('abandon-scope')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('abandon-wait-20')),
          matching: find.text('22%'),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byType(DropdownButton<String?>));
      await tick(tester);
      await tester.tap(find.text('Clinica').last);
      await tick(tester);
      expect(
        tester.widget<Text>(find.byKey(const ValueKey('abandon-scope'))).data,
        contains('Clinica'),
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('abandon-wait-20')),
          matching: find.text('22%'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('abandon-capacity-card')),
        findsOneWidget,
      );
      expect(find.text('Nenhum horário crítico no período'), findsOneWidget);
    });

    testWidgets('aviso de histórico truncado vale para desistências', (
      tester,
    ) async {
      final many = [
        for (var i = 0; i < 500; i++)
          biEntry(
            'm$i',
            joined: DateTime.utc(2025, 6, 14, 12, i % 50),
            called: DateTime.utc(2025, 6, 14, 12, i % 50 + 2),
            finished: DateTime.utc(2025, 6, 14, 12, i % 50 + 5),
          ),
      ];
      await open(tester, biData(many));
      expect(find.byKey(const ValueKey('abandon-truncated')), findsOneWidget);
    });

    testWidgets('maior taxa some quando todas as taxas são zero', (
      tester,
    ) async {
      final calm = abandonEntries()
          .where((e) => e.id.startsWith('h9'))
          .toList();
      await open(tester, biData(calm));
      expect(find.byKey(const ValueKey('abandon-hour-peak')), findsNothing);
      expect(
        find.byKey(const ValueKey('abandon-hour-rate-bars')),
        findsOneWidget,
      );
    });

    testWidgets('fala taxa por 10 min e contagem em frases separadas', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await open(tester, biData(abandonEntries()));
      expect(
        find.bySemanticsLabel(
          '20–40 min: 22% a cada 10 min. 4 de 9 desistiram',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('limite exibido não passa de 100%', (tester) async {
      final j = DateTime.utc(2025, 6, 14, 12);
      final tight = [
        for (var k = 0; k < 5; k++)
          biEntry(
            't$k',
            result: 'left',
            joined: j,
            finished: j.add(Duration(seconds: 40 * 60 + k * 7)),
          ),
      ];
      await open(tester, biData(tight));
      final texts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('abandon-wait-40')),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .toList();
      expect(texts, ['40+ min', '100%']);
    });

    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      testWidgets('cartão de capacidade tem contraste >= 3:1 ($mode)', (
        tester,
      ) async {
        await pumpApp(
          tester,
          screen(biData(abandonEntries())),
          themeMode: mode,
          size: tall,
        );
        await tick(tester);
        final box = tester.widget<Container>(
          find.byKey(const ValueKey('abandon-capacity-card')),
        );
        final border = (box.decoration! as BoxDecoration).border! as Border;
        final palette = mode == ThemeMode.dark
            ? QioPalette.dark
            : QioPalette.light;
        expect(
          contrastRatio(border.top.color, palette.card),
          greaterThanOrEqualTo(3),
        );
      });
    }

    testWidgets('cabeçalho ordenável é acionável por semântica', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await open(tester, biData(attendantEntries()));
      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('Ordenar por Atendimento médio')),
      );
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      tester.semantics.tap(
        find.semantics.byLabel(RegExp('Ordenar por Atendimento médio')),
      );
      await tick(tester);
      handle.dispose();
    });

    testWidgets('relatório é calculado uma vez por combinação', (tester) async {
      await open(tester, biData([...attendantEntries(), ...abandonEntries()]));
      final base = metricsReportBuilds;
      expect(base, greaterThan(0));
      await tester.tap(find.byKey(const ValueKey('attendants-sort-service')));
      await tick(tester);
      await tester.tap(find.byKey(const ValueKey('attendants-mode-shift')));
      await tick(tester);
      expect(metricsReportBuilds, base);
      await tester.tap(chip('Tudo'));
      await tick(tester);
      expect(metricsReportBuilds, base + 1);
    });
  });

  group('textos e constantes', () {
    for (final locale in const ['pt', 'en', 'es']) {
      test('textos de ajuda refletem as constantes ($locale)', () {
        final l = lookupAppLocalizations(Locale(locale));
        String how(BiIndicator i) => biInfoTexts(l, i).how;
        expect(
          how(BiIndicator.attendantService),
          contains('$minServiceSamples'),
        );
        expect(
          how(BiIndicator.attendantDeviation),
          contains('$minServiceSamples'),
        );
        final rate = how(BiIndicator.attendantRate);
        expect(rate, contains('$defaultMinRateSamples'));
        expect(rate, contains('$defaultMinWindowMin'));
        expect(how(BiIndicator.attendantIdle), contains('$defaultIdleCapMin'));
        for (final i in [
          BiIndicator.abandonWait,
          BiIndicator.abandonEstimate,
          BiIndicator.estimateAccuracy,
          BiIndicator.abandonHour,
        ]) {
          expect(how(i), contains('$defaultAbandonMinSamples'), reason: '$i');
        }
        expect(
          how(BiIndicator.abandonInflection),
          contains('${(defaultInflectionThreshold * 100).round()}%'),
        );
        final cap = how(BiIndicator.capacitySignal);
        expect(cap, contains('${defaultWaitThresholdMin.round()} min'));
        expect(cap, contains('${(defaultInflectionThreshold * 100).round()}%'));
        expect(
          how(BiIndicator.abandonWait),
          contains(bandsText(defaultWaitBandEdges)),
        );
        expect(
          how(BiIndicator.abandonEstimate),
          contains(bandsText(defaultEstimateBandEdges)),
        );
        for (final i in [
          BiIndicator.goalWait,
          BiIndicator.goalService,
          BiIndicator.goalMissed,
        ]) {
          expect(how(i), contains('$defaultGoalMinSamples'), reason: '$i');
        }
        expect(
          how(BiIndicator.staffingService),
          contains('$defaultMinServiceSamples'),
        );
        expect(
          how(BiIndicator.staffingRequired),
          contains('${occupancyPct(defaultTargetOccupancy)}%'),
        );
        expect(how(BiIndicator.staffingGap), contains('$defaultDeficitLimit'));
        final season = how(BiIndicator.seasonVolume);
        expect(season, contains('$seasonWeeks'));
        expect(season, contains('${stableTrendPct.round()}%'));
        expect(season, contains('$minSeasonWeeks'));
        final pattern = how(BiIndicator.seasonPattern);
        expect(pattern, contains('$seasonTopCells'));
        expect(pattern, contains('$recurrencePct%'));
        expect(pattern, contains('$minSeasonWeeks'));
      });
    }

    test('valores atuais das constantes conferem com o texto em pt', () {
      final l = lookupAppLocalizations(const Locale('pt'));
      expect(minServiceSamples, 3);
      expect(defaultMinRateSamples, 3);
      expect(defaultMinWindowMin, 30);
      expect(defaultIdleCapMin, 30);
      expect(defaultAbandonMinSamples, 5);
      expect(defaultInflectionThreshold, 0.2);
      expect(defaultWaitThresholdMin, 15);
      expect(defaultGoalMinSamples, 5);
      expect(defaultTargetOccupancy, 0.85);
      expect(defaultMinServiceSamples, 3);
      expect(defaultDeficitLimit, 5);
      expect(seasonWeeks, 8);
      expect(minSeasonWeeks, 3);
      expect(seasonTopCells, 5);
      expect(recurrencePct, 70);
      expect(stableTrendPct, 5);
      expect(
        biInfoTexts(l, BiIndicator.staffingRequired).how,
        contains('ocupação-alvo de 85%'),
      );
      expect(
        l.capacityCardBody('11h', waitThresholdRounded(), inflectionLimitPct()),
        'Nestes horários a espera média é de 15 min ou mais e 20% ou mais '
        'desistem: 11h. Considere reforçar o atendimento.',
      );
      expect(
        biInfoTexts(l, BiIndicator.attendantIdle).how,
        contains('menor ou igual a 30 min'),
      );
      expect(
        l.abandonInflectionNone(inflectionLimitPct()),
        'Nenhuma faixa passa do limite de 20% a cada 10 min.',
      );
    });
  });
}
