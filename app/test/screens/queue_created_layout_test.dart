import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/screens/queue_created_screen.dart';

import '../helpers/create_queue_flow.dart';
import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

final queue = Queue(
  id: 'abc123',
  ownerId: 'uid-1',
  name: 'Clínica Sol',
  avgServiceMin: 10,
  createdAt: DateTime(2026, 10, 1),
);

Widget marker(BuildContext context, QueueCreatedTarget target) =>
    Scaffold(body: Text('dest:${target.name}'));

Future<void> pumpCreated(
  WidgetTester tester, {
  required Size size,
  double scale = 1,
}) async {
  await pumpApp(
    tester,
    Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: QueueCreatedScreen(
          queue: queue,
          queues: FakeQueueService(),
          onShare: (_) async {},
          destinationBuilder: marker,
        ),
      ),
    ),
    size: size,
  );
}

void main() {
  group('Fila criada', () {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('320 px com texto ${scale}x rola sem overflow', (
        tester,
      ) async {
        await pumpCreated(tester, size: const Size(320, 568), scale: scale);
        expect(tester.takeException(), isNull);
        await tester.dragUntilVisible(
          byKeyName('created-share'),
          find.byType(ListView),
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();
        expect(byKeyName('created-share'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('900 px centraliza com largura máxima', (tester) async {
      await pumpCreated(tester, size: const Size(900, 900));
      final qr = tester.getRect(byKeyName('created-qr'));
      expect(qr.center.dx, closeTo(450, 1));
      final title = tester.getRect(byKeyName('created-title'));
      expect(title.center.dx, closeTo(450, 1));
      final list = tester.getRect(find.byType(ListView));
      expect(list.width, lessThanOrEqualTo(520));
      expect(list.center.dx, closeTo(450, 1));
      expect(tester.takeException(), isNull);
    });
  });

  group('gate do limite', () {
    for (final entry in {
      '320': const Size(320, 568),
      '900': const Size(900, 900),
    }.entries) {
      for (final scale in [1.0, 2.0]) {
        testWidgets('${entry.key} px com texto ${scale}x', (tester) async {
          final queues = FakeQueueService()..atLimit = true;
          await pumpCreate(
            tester,
            queues: queues,
            size: entry.value,
            textScale: scale,
          );
          expect(byKeyName('create-limit-title'), findsOneWidget);
          expect(tester.takeException(), isNull);
          final button = tester.getRect(byKeyName('create-limit-back'));
          final width = entry.value.width;
          expect(button.width, lessThanOrEqualTo(520));
          expect(button.center.dx, closeTo(width / 2, 1));
          expect(button.left, greaterThanOrEqualTo(0));
          expect(button.right, lessThanOrEqualTo(width));
        });
      }
    }
  });
}
