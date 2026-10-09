import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/screens/create_queue_screen.dart';

import '../helpers/create_queue_flow.dart';
import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

const limitText =
    'Limite de 20 filas atingido. Exclua uma fila para criar outra.';

void main() {
  testWidgets('limite atingido bloqueia o wizard', (tester) async {
    final queues = FakeQueueService()..atLimit = true;
    await pumpCreate(tester, queues: queues);
    expect(find.text(limitText), findsOneWidget);
    expect(byKeyName('create-limit-back'), findsOneWidget);
    expect(byKeyName('create-name'), findsNothing);
    expect(byKeyName('create-progress'), findsNothing);
    expect(queues.limitChecks, 1);
  });

  testWidgets('botão voltar sai da tela', (tester) async {
    final queues = FakeQueueService()..atLimit = true;
    await pumpApp(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  CreateQueueScreen(queues: queues, groups: FakeGroupService()),
            ),
          ),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(byKeyName('create-limit-back'), findsOneWidget);
    await tapKey(tester, 'create-limit-back');
    expect(byKeyName('create-limit-back'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('spinner durante a checagem e segue abaixo do limite', (
    tester,
  ) async {
    final gate = Completer<void>();
    final queues = FakeQueueService()..limitGate = gate.future;
    await pumpApp(
      tester,
      CreateQueueScreen(queues: queues, groups: FakeGroupService()),
    );
    expect(byKeyName('create-limit-checking'), findsOneWidget);
    expect(byKeyName('create-name'), findsNothing);
    gate.complete();
    await tester.pumpAndSettle();
    expect(byKeyName('create-limit-checking'), findsNothing);
    expect(byKeyName('create-name'), findsOneWidget);
    expect(find.text(limitText), findsNothing);
  });

  testWidgets('falha na checagem segue para o wizard', (tester) async {
    final queues = FakeQueueService()..limitCheckError = Exception('offline');
    await pumpCreate(tester, queues: queues);
    expect(byKeyName('create-name'), findsOneWidget);
    expect(find.text(limitText), findsNothing);
  });

  testWidgets('en: mensagem localizada', (tester) async {
    final queues = FakeQueueService()..atLimit = true;
    await pumpApp(
      tester,
      CreateQueueScreen(queues: queues, groups: FakeGroupService()),
      locale: const Locale('en'),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('20'), findsWidgets);
    expect(find.text('Queue limit reached'), findsOneWidget);
  });
}
