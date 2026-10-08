import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/screens/create_queue_screen.dart';
import 'package:qio_app/services/queue_service.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

const limitText =
    'Limite de 20 filas atingido. Exclua uma fila para criar outra.';
const genericText = 'Não foi possível concluir a ação. Tente novamente.';

Future<void> submit(WidgetTester tester, FakeQueueService queues) async {
  await pumpApp(
    tester,
    CreateQueueScreen(queues: queues, groups: FakeGroupService()),
    size: const Size(390, 1800),
  );
  final fields = find.byType(TextFormField);
  await tester.enterText(fields.at(0), 'Clínica');
  await tester.enterText(fields.at(2), '15');
  await tester.ensureVisible(find.text('Criar fila'));
  await tester.tap(find.text('Criar fila'));
  await tester.pumpAndSettle();
}

void main() {
  test('limit is reached at maxQueuesPerOwner', () {
    expect(maxQueuesPerOwner, 20);
    expect(isQueueLimitReached(maxQueuesPerOwner - 1), isFalse);
    expect(isQueueLimitReached(maxQueuesPerOwner), isTrue);
    expect(isQueueLimitReached(maxQueuesPerOwner + 5), isTrue);
  });

  testWidgets('create screen shows limit message', (tester) async {
    await submit(
      tester,
      FakeQueueService()..createError = const QueueLimitReached(),
    );
    expect(find.text(limitText), findsOneWidget);
    expect(find.text(genericText), findsNothing);
  });

  testWidgets('create screen keeps generic error for other failures', (
    tester,
  ) async {
    await submit(tester, FakeQueueService()..createError = Exception('boom'));
    expect(find.text(genericText), findsOneWidget);
    expect(find.text(limitText), findsNothing);
  });
}
