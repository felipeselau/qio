import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_goals.dart';
import 'package:qio_app/screens/metrics_screen.dart';
import 'package:qio_app/services/metrics_export.dart';

import '../helpers/bi_data.dart';
import '../helpers/pump_app.dart';

const tall = Size(390, 16000);

Future<void> tick(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

Widget screen(List<QueueHistoryInput> data) =>
    MetricsScreen(loader: () async => data, clock: () => biNow);

Future<void> open(
  WidgetTester tester,
  List<QueueHistoryInput> data, {
  Locale locale = const Locale('pt'),
  ThemeMode themeMode = ThemeMode.light,
  Size size = tall,
}) async {
  await pumpApp(
    tester,
    screen(data),
    size: size,
    locale: locale,
    themeMode: themeMode,
  );
  await tick(tester);
}

String text(WidgetTester tester, String key) =>
    tester.widget<Text>(find.byKey(ValueKey(key))).data!;

List<QueueHistoryInput> goalsData() => biData(goalEntries(), goals: biGoals);

void main() {
  group('metas', () {
    testWidgets('cartões, selos e valores', (tester) async {
      await open(tester, goalsData());
      expect(find.byKey(const ValueKey('goals-section')), findsOneWidget);
      expect(text(tester, 'goals-wait-pct'), '60%');
      expect(text(tester, 'goals-service-pct'), '80%');
      expect(text(tester, 'goals-wait-counts'), '3 de 5 dentro do limite');
      expect(text(tester, 'goals-service-counts'), '4 de 5 dentro do limite');
      expect(text(tester, 'goals-wait-target'), 'Alvo: 80% dentro do limite');
      expect(find.text('Não atingida'), findsOneWidget);
      expect(find.text('Atingida'), findsOneWidget);
      expect(text(tester, 'goals-queues-count'), 'Meta de 1 fila no escopo');
    });

    testWidgets('períodos não atingidos e maior violação', (tester) async {
      await open(tester, goalsData());
      expect(
        text(tester, 'goals-missed-wait-20250614'),
        'Espera, 14/06: 60% (3 de 5), alvo 80%',
      );
      expect(
        find.byKey(const ValueKey('goals-missed-service-20250614')),
        findsNothing,
      );
      expect(
        text(tester, 'goals-missed-wait-hours'),
        'Espera, horas abaixo do alvo: 12h',
      );
      expect(
        text(tester, 'goals-worst-wait'),
        'Maior violação de espera: 10 min acima da meta, em 14/06.',
      );
      expect(
        text(tester, 'goals-worst-service'),
        'Maior violação de atendimento: 4 min acima da meta, em 14/06.',
      );
    });

    testWidgets('um dia só não desenha o gráfico diário', (tester) async {
      await open(tester, goalsData());
      expect(find.byKey(const ValueKey('goals-wait-daily')), findsNothing);
    });

    testWidgets('gráfico diário aparece com mais de um dia', (tester) async {
      final second = [
        for (var i = 0; i < 5; i++)
          biEntry(
            'd$i',
            joined: DateTime.utc(2025, 6, 13, 15),
            called: DateTime.utc(2025, 6, 13, 15, 2),
            finished: DateTime.utc(2025, 6, 13, 15, 6),
            calledBy: 'op1',
          ),
      ];
      await open(tester, biData([...goalEntries(), ...second], goals: biGoals));
      expect(find.byKey(const ValueKey('goals-wait-daily')), findsOneWidget);
      expect(find.byKey(const ValueKey('goals-service-daily')), findsOneWidget);
      Finder label(String text) => find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == text,
      );
      expect(label('2 dias avaliados, 1 abaixo do alvo'), findsOneWidget);
      expect(label('2 dias avaliados, 0 abaixo do alvo'), findsOneWidget);
    });

    testWidgets('amostra pequena não mostra selo', (tester) async {
      await open(
        tester,
        biData(goalEntries().take(3).toList(), goals: biGoals),
      );
      expect(find.byKey(const ValueKey('goals-wait-small')), findsOneWidget);
      expect(find.byKey(const ValueKey('goals-wait-badge')), findsNothing);
      expect(find.byKey(const ValueKey('goals-wait-pct')), findsOneWidget);
    });

    testWidgets('sem metas mostra chamada para configurar', (tester) async {
      await open(tester, biData(goalEntries()));
      expect(find.byKey(const ValueKey('goals-empty-cta')), findsOneWidget);
      expect(find.byKey(const ValueKey('goals-wait-card')), findsNothing);
    });

    testWidgets('meta definida sem amostras mostra estado vazio', (
      tester,
    ) async {
      final quickLeft = biEntry(
        'q',
        result: 'left',
        joined: DateTime.utc(2025, 6, 14, 15),
        finished: DateTime.utc(2025, 6, 14, 15, 2),
      );
      await open(tester, biData([quickLeft], goals: biGoals));
      expect(find.byKey(const ValueKey('goals-wait-empty')), findsOneWidget);
      expect(find.byKey(const ValueKey('goals-service-empty')), findsOneWidget);
      expect(find.byKey(const ValueKey('goals-no-violation')), findsNothing);
    });

    testWidgets('só espera configurada esconde o cartão de atendimento', (
      tester,
    ) async {
      await open(
        tester,
        biData(goalEntries(), goals: const QueueGoals(maxWaitMin: 10)),
      );
      expect(find.byKey(const ValueKey('goals-wait-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('goals-service-card')), findsNothing);
    });

    testWidgets('botão i abre a ajuda da meta de espera', (tester) async {
      await open(tester, goalsData());
      final btn = find.byKey(const ValueKey('info-goalWait'));
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tick(tester);
      expect(find.byKey(const ValueKey('info-sheet-goalWait')), findsOneWidget);
      expect(find.textContaining('desistiu só entra'), findsOneWidget);
    });
  });

  group('planejamento de equipe', () {
    testWidgets('grade nos três modos', (tester) async {
      await open(tester, biData(planningEntries()));
      expect(find.byKey(const ValueKey('staffing-section')), findsOneWidget);
      expect(text(tester, 'staffing-cell-0-12'), '2');
      expect(text(tester, 'staffing-cell-1-10'), '1');
      expect(text(tester, 'staffing-cell-3-3'), '');
      await tester.tap(find.byKey(const ValueKey('staffing-mode-observed')));
      await tick(tester);
      expect(text(tester, 'staffing-cell-0-12'), '2,0');
      expect(text(tester, 'staffing-cell-1-10'), '');
      await tester.tap(find.byKey(const ValueKey('staffing-mode-gap')));
      await tick(tester);
      expect(text(tester, 'staffing-cell-0-12'), '0');
      expect(text(tester, 'staffing-cell-1-10'), '+1,0');
    });

    testWidgets('tempo médio, base e maiores déficits', (tester) async {
      await open(tester, biData(planningEntries()));
      expect(
        text(tester, 'staffing-service'),
        'Tempo médio de atendimento: 20,0 min (4 atendimentos)',
      );
      expect(
        text(tester, 'staffing-basis'),
        'Ocupação-alvo: 85% · Base: 2 dias com dados',
      );
      expect(
        text(tester, 'staffing-top-0'),
        'terça-feira 10h: precisa de 1, tem 0,0',
      );
      expect(find.byKey(const ValueKey('staffing-top-1')), findsNothing);
    });

    testWidgets('sazonalidade com tendência e padrão recorrente', (
      tester,
    ) async {
      await open(tester, biData(planningEntries()));
      expect(
        find.byKey(const ValueKey('staffing-weekly-bars')),
        findsOneWidget,
      );
      expect(
        text(tester, 'staffing-trend'),
        'Volume estável: variação abaixo de 5% por semana.',
      );
      expect(
        text(tester, 'staffing-recurring-0'),
        'segunda-feira 12h: entre as mais cheias em 4 de 4 semanas',
      );
    });

    testWidgets('menos de 3 semanas mostra dados insuficientes', (
      tester,
    ) async {
      final current = planningEntries()
          .where((e) => e.joinedAt.isAfter(DateTime.utc(2025, 6, 8)))
          .toList();
      await open(tester, biData(current));
      expect(
        text(tester, 'staffing-season-insufficient'),
        'Dados insuficientes: são necessárias pelo menos 3 semanas completas '
        'com dados (há 0).',
      );
      expect(find.byKey(const ValueKey('staffing-weekly-bars')), findsNothing);
      expect(find.byKey(const ValueKey('staffing-trend')), findsNothing);
      expect(text(tester, 'staffing-top-0'), contains('precisa de 1'));
    });

    testWidgets('sem amostras de atendimento só o modo observado', (
      tester,
    ) async {
      final entries = [
        biEntry(
          's1',
          joined: DateTime.utc(2025, 6, 9, 15),
          called: DateTime.utc(2025, 6, 9, 15),
          finished: DateTime.utc(2025, 6, 9, 15, 10),
          calledBy: 'op1',
        ),
        biEntry(
          'l1',
          result: 'left',
          joined: DateTime.utc(2025, 6, 9, 16),
          finished: DateTime.utc(2025, 6, 9, 16, 3),
        ),
      ];
      await open(tester, biData(entries));
      expect(
        text(tester, 'staffing-service'),
        'Tempo médio indisponível: são necessários pelo menos 3 atendimentos '
        'concluídos.',
      );
      expect(
        find.byKey(const ValueKey('staffing-mode-required')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('staffing-mode-observed')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('staffing-top-unavailable')),
        findsOneWidget,
      );
    });

    testWidgets('botão i do tempo médio abre a ajuda', (tester) async {
      await open(tester, biData(planningEntries()));
      final btn = find.byKey(const ValueKey('info-staffingService'));
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tick(tester);
      expect(
        find.byKey(const ValueKey('info-sheet-staffingService')),
        findsOneWidget,
      );
    });
  });

  group('layout', () {
    for (final width in [320.0, 390.0]) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('largura $width texto ${scale}x sem overflow', (
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
                  biData([
                    ...goalEntries(),
                    ...planningEntries(),
                  ], goals: biGoals),
                ),
              ),
            ),
            size: Size(width, 20000),
          );
          await tick(tester);
          expect(find.byKey(const ValueKey('goals-section')), findsOneWidget);
          expect(
            find.byKey(const ValueKey('staffing-section')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        });
      }
    }

    for (final locale in const ['en', 'es']) {
      testWidgets('$locale escuro 320', (tester) async {
        await open(
          tester,
          biData([...goalEntries(), ...planningEntries()], goals: biGoals),
          locale: Locale(locale),
          themeMode: ThemeMode.dark,
          size: const Size(320, 16000),
        );
        expect(find.byKey(const ValueKey('goals-section')), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
