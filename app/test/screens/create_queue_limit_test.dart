import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/services/queue_service.dart';
import 'package:qio_app/widgets/queue_panel/duplicate_queue_tile.dart';

import '../helpers/create_queue_flow.dart';
import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

const limitText =
    'Limite de 20 filas atingido. Exclua uma fila para criar outra.';
const genericText = 'Não foi possível concluir a ação. Tente novamente.';

Future<void> submit(
  WidgetTester tester,
  FakeQueueService queues, {
  bool viaReview = false,
}) async {
  await pumpCreate(tester, queues: queues);
  await typeName(tester, 'Clínica');
  if (viaReview) {
    await continueSteps(tester, 5);
    await tapKey(tester, 'create-submit');
  } else {
    await tapKey(tester, 'create-quick');
  }
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

  testWidgets('review step shows limit message and allows retry', (
    tester,
  ) async {
    final queues = FakeQueueService()..createError = const QueueLimitReached();
    await submit(tester, queues, viaReview: true);
    expect(find.text(limitText), findsOneWidget);
    expect(byKeyName('create-submit'), findsOneWidget);

    queues.createError = null;
    await tapKey(tester, 'create-submit');
    expect(find.text(limitText), findsNothing);
    expect(queues.calls, ['create:Clínica:queue:0']);
  });

  testWidgets('create screen keeps generic error for other failures', (
    tester,
  ) async {
    await submit(tester, FakeQueueService()..createError = Exception('boom'));
    expect(find.text(genericText), findsOneWidget);
    expect(find.text(limitText), findsNothing);
  });

  testWidgets('duplicate shows limit message', (tester) async {
    final queues = FakeQueueService()
      ..duplicateError = const QueueLimitReached();
    await pumpApp(
      tester,
      Scaffold(
        body: DuplicateQueueTile(
          queue: Queue(
            id: 'q1',
            ownerId: 'uid-1',
            name: 'Padaria',
            avgServiceMin: 7,
            createdAt: DateTime(2025, 5, 20),
          ),
          queues: queues,
        ),
      ),
    );
    await tester.tap(find.byType(DuplicateQueueTile));
    await tester.pumpAndSettle();
    expect(find.text(limitText), findsOneWidget);
  });
}
