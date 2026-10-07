import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/screens/metrics_screen.dart';
import 'package:qio_app/services/metrics_export.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

const tall = Size(390, 2400);

Future<void> tick(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

Finder chip(String label) => find.widgetWithText(ChoiceChip, label);

final fixedNow = DateTime(2025, 6, 15, 12);

MetricsScreen screen({Future<List<QueueHistoryInput>> Function()? loader}) =>
    MetricsScreen(loader: loader ?? sample, clock: () => fixedNow);

Future<List<QueueHistoryInput>> sample() async {
  final now = fixedNow;
  return [
    QueueHistoryInput(
      fakeQueue('a', name: 'Padaria'),
      [
        fakeHistory(
          'h1',
          1,
          finishedAt: now.subtract(const Duration(minutes: 5)),
        ),
        fakeHistory(
          'h2',
          2,
          finishedAt: now.subtract(const Duration(minutes: 20)),
        ),
        fakeHistory(
          'h3',
          3,
          result: 'no_show',
          finishedAt: now.subtract(const Duration(minutes: 30)),
        ),
        fakeHistory(
          'h4',
          4,
          finishedAt: now.subtract(const Duration(days: 20)),
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
}

void main() {
  testWidgets('shows skeleton while loading', (tester) async {
    await pumpApp(tester, screen(), size: tall);
    expect(find.text('Métricas'), findsOneWidget);
    expect(find.text('Filas mais ativas'), findsNothing);
    await tick(tester);
  });

  testWidgets('no queues shows the empty state', (tester) async {
    await pumpApp(tester, screen(loader: () async => []), size: tall);
    await tick(tester);
    expect(find.text('Você ainda não tem filas'), findsOneWidget);
    expect(find.byIcon(Icons.file_download_outlined), findsNothing);
  });

  testWidgets('loader error shows the retry state', (tester) async {
    await pumpApp(
      tester,
      screen(loader: () async => throw Exception('x')),
      size: tall,
    );
    await tick(tester);
    expect(
      find.text('Não foi possível carregar as métricas. Tente novamente.'),
      findsOneWidget,
    );
  });

  testWidgets('queues without history show the no-data state', (tester) async {
    await pumpApp(
      tester,
      screen(
        loader: () async => [
          QueueHistoryInput(fakeQueue('a'), const [], const [], const []),
        ],
      ),
      size: tall,
    );
    await tick(tester);
    expect(find.text('Nenhum atendimento no período'), findsOneWidget);
    expect(find.text('Filas mais ativas'), findsNothing);
  });

  testWidgets('default period is 7 days and excludes older entries', (
    tester,
  ) async {
    await pumpApp(tester, screen(), size: tall);
    await tick(tester);
    expect(find.text('Atendimentos'), findsOneWidget);
    expect(find.text('3'), findsWidgets);
    expect(find.text('1 (33%)'), findsOneWidget);
    expect(find.text('Filas mais ativas'), findsOneWidget);
    expect(find.text('Padaria'), findsOneWidget);
    expect(find.textContaining('Horários mais cheios'), findsWidgets);
  });

  testWidgets('period selector recomputes the totals', (tester) async {
    await pumpApp(tester, screen(), size: tall);
    await tick(tester);
    await tester.tap(chip('Tudo'));
    await tick(tester);
    expect(find.text('1 (25%)'), findsOneWidget);
    expect(find.text('4'), findsWidgets);

    await tester.tap(chip('Hoje'));
    await tick(tester);
    expect(find.text('1 (33%)'), findsOneWidget);
  });

  testWidgets('operator filter narrows the per-attendant section', (
    tester,
  ) async {
    await pumpApp(tester, screen(), size: tall);
    await tick(tester);
    expect(
      find.text('Nenhum atendimento por atendente no período'),
      findsNothing,
    );
    await tester.tap(find.byType(DropdownButton<String?>));
    await tick(tester);
    await tester.tap(find.text('Clinica').last);
    await tick(tester);
    expect(
      find.text('Nenhum atendimento por atendente no período'),
      findsOneWidget,
    );
  });

  testWidgets('export action is available once data is loaded', (tester) async {
    await pumpApp(tester, screen(), size: tall);
    await tick(tester);
    await tester.tap(find.byIcon(Icons.file_download_outlined));
    await tick(tester);
    expect(find.text('Exportar CSV'), findsOneWidget);
    expect(find.text('Exportar PDF'), findsOneWidget);
  });

  testWidgets('renders in English dark at 320 width', (tester) async {
    await pumpApp(
      tester,
      screen(),
      locale: const Locale('en'),
      themeMode: ThemeMode.dark,
      size: const Size(320, 2400),
    );
    await tick(tester);
    expect(find.text('Metrics'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
