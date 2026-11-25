import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_goals.dart';
import 'package:qio_app/widgets/queue_panel/goals_tile.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

Future<FakeQueueService> open(
  WidgetTester tester, {
  QueueGoals? goals,
  FakeQueueService? queues,
}) async {
  final q = queues ?? FakeQueueService();
  await pumpApp(
    tester,
    Scaffold(
      body: SingleChildScrollView(
        child: GoalsTile(queueId: 'q1', goals: goals, queues: q),
      ),
    ),
  );
  return q;
}

Future<void> enter(WidgetTester tester, String key, String value) async {
  await tester.enterText(
    find.descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(TextFormField),
    ),
    value,
  );
}

String summary(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const ValueKey('goals-summary'))).data!;

void main() {
  testWidgets('sem metas mostra o texto padrão', (tester) async {
    await open(tester);
    expect(find.text('Metas de atendimento'), findsOneWidget);
    expect(summary(tester), 'Sem metas definidas');
  });

  testWidgets('resume as metas definidas', (tester) async {
    await open(
      tester,
      goals: const QueueGoals(maxWaitMin: 15, maxServiceMin: 10, targetPct: 90),
    );
    expect(
      summary(tester),
      'Espera até 15 min · Atendimento até 10 min · alvo 90%',
    );
    await open(tester, goals: const QueueGoals(maxServiceMin: 8));
    expect(summary(tester), 'Atendimento até 8 min · alvo 80%');
  });

  testWidgets('salva espera e alvo padrão ausente', (tester) async {
    final q = await open(tester);
    await tester.tap(find.byKey(const ValueKey('goals-tile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goals-remove')), findsNothing);
    await enter(tester, 'goals-wait', '15');
    await tester.tap(find.byKey(const ValueKey('goals-save')));
    await tester.pumpAndSettle();
    expect(q.calls, ['goals:q1:15:null:null']);
    expect(find.byKey(const ValueKey('goals-save')), findsNothing);
  });

  testWidgets('salva os três campos', (tester) async {
    final q = await open(tester);
    await tester.tap(find.byKey(const ValueKey('goals-tile')));
    await tester.pumpAndSettle();
    await enter(tester, 'goals-wait', '20');
    await enter(tester, 'goals-service', '12');
    await enter(tester, 'goals-target', '95');
    await tester.tap(find.byKey(const ValueKey('goals-save')));
    await tester.pumpAndSettle();
    expect(q.calls, ['goals:q1:20:12:95']);
  });

  testWidgets('valida faixas e não salva', (tester) async {
    final q = await open(tester);
    await tester.tap(find.byKey(const ValueKey('goals-tile')));
    await tester.pumpAndSettle();
    await enter(tester, 'goals-wait', '0');
    await enter(tester, 'goals-service', '241');
    await enter(tester, 'goals-target', '49');
    await tester.tap(find.byKey(const ValueKey('goals-save')));
    await tester.pumpAndSettle();
    expect(find.text('Informe de 1 a 240 minutos.'), findsNWidgets(2));
    expect(find.text('Informe de 50 a 100%.'), findsOneWidget);
    expect(q.calls, isEmpty);
    await enter(tester, 'goals-wait', 'abc');
    await tester.tap(find.byKey(const ValueKey('goals-save')));
    await tester.pumpAndSettle();
    expect(find.text('Informe de 1 a 240 minutos.'), findsNWidgets(2));
    expect(q.calls, isEmpty);
  });

  testWidgets('sem espera nem atendimento exige uma meta', (tester) async {
    final q = await open(tester);
    await tester.tap(find.byKey(const ValueKey('goals-tile')));
    await tester.pumpAndSettle();
    await enter(tester, 'goals-target', '90');
    await tester.tap(find.byKey(const ValueKey('goals-save')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('goals-error-none')), findsOneWidget);
    expect(q.calls, isEmpty);
  });

  testWidgets('abre preenchido e remove as metas', (tester) async {
    final q = await open(
      tester,
      goals: const QueueGoals(maxWaitMin: 15, targetPct: 70),
    );
    await tester.tap(find.byKey(const ValueKey('goals-tile')));
    await tester.pumpAndSettle();
    expect(find.text('15'), findsOneWidget);
    expect(find.text('70'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('goals-remove')));
    await tester.pumpAndSettle();
    expect(q.calls, ['goals:q1:null']);
  });

  testWidgets('cancelar não grava', (tester) async {
    final q = await open(tester);
    await tester.tap(find.byKey(const ValueKey('goals-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('goals-cancel')));
    await tester.pumpAndSettle();
    expect(q.calls, isEmpty);
  });

  testWidgets('erro ao gravar mostra aviso', (tester) async {
    final q = FakeQueueService()..goalsError = Exception('x');
    await open(tester, queues: q);
    await tester.tap(find.byKey(const ValueKey('goals-tile')));
    await tester.pumpAndSettle();
    await enter(tester, 'goals-wait', '10');
    await tester.tap(find.byKey(const ValueKey('goals-save')));
    await tester.pumpAndSettle();
    expect(
      find.text('Não foi possível concluir a ação. Tente novamente.'),
      findsOneWidget,
    );
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('diálogo sem overflow em 320 com texto ${scale}x', (
      tester,
    ) async {
      await pumpApp(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: GoalsTile(
                queueId: 'q1',
                goals: const QueueGoals(maxWaitMin: 15, targetPct: 90),
                queues: FakeQueueService(),
              ),
            ),
          ),
        ),
        size: const Size(320, 640),
      );
      await tester.tap(find.byKey(const ValueKey('goals-tile')));
      await tester.pumpAndSettle();
      await enter(tester, 'goals-wait', '0');
      await tester.tap(find.byKey(const ValueKey('goals-save')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
