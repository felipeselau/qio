import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/controllers/create_queue_controller.dart';
import 'package:qio_app/controllers/create_queue_draft.dart';
import 'package:qio_app/models/queue_slot.dart';
import 'package:qio_app/widgets/create_queue/create_queue_parts.dart';

import '../helpers/create_queue_flow.dart';
import '../helpers/fake_draft_store.dart';

const sizes = {
  '320': Size(320, 640),
  '390': Size(390, 844),
  '900': Size(900, 900),
};

Future<void> walkAllSteps(WidgetTester tester) async {
  await typeName(tester, 'Clínica');
  await tapKey(tester, 'create-continue');
  await tapKey(tester, 'create-mode-schedule');
  await tapKey(tester, 'create-suggest-60');
  for (final key in List.filled(4, 'create-continue')) {
    expect(tester.takeException(), isNull);
    await tapKey(tester, key);
  }
  expect(tester.takeException(), isNull);
  await tapKey(tester, 'create-continue');
  expect(byKeyName('create-submit'), findsOneWidget);
  expect(tester.takeException(), isNull);
}

FakeCreateQueueDraftStore twentySlotsStore() {
  final slots = [
    for (var i = 0; i < 20; i++)
      QueueSlot(
        id: 's$i',
        start:
            '${(8 + i ~/ 2).toString().padLeft(2, '0')}:${i.isEven ? '00' : '30'}',
        capacity: 1,
      ),
  ];
  return FakeCreateQueueDraftStore(
    initial: {
      'u1': CreateQueueController(
        draft: CreateQueueDraft(
          name: 'Clínica',
          mode: QueueMode.schedule,
          slots: slots,
        ),
        step: CreateQueueStep.mode,
      ).toJson(),
    },
  );
}

void main() {
  group('passos sem overflow', () {
    for (final entry in sizes.entries) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets('largura ${entry.key} com texto ${scale}x', (tester) async {
          await pumpCreate(tester, size: entry.value, textScale: scale);
          await walkAllSteps(tester);
        });
      }
    }
  });

  group('largura máxima', () {
    testWidgets('900 px: passos e rodapé limitados e alinhados', (
      tester,
    ) async {
      await pumpCreate(tester, size: sizes['900']!);
      final field = tester.getRect(byKeyName('create-name'));
      final button = tester.getRect(byKeyName('create-continue'));
      expect(field.width, lessThanOrEqualTo(createQueueMaxWidth));
      expect(button.width, lessThanOrEqualTo(createQueueMaxWidth));
      expect(field.center.dx, closeTo(450, 1));
      expect(button.center.dx, closeTo(450, 1));
      expect(button.left, closeTo(field.left, 1));
      expect(button.right, closeTo(field.right, 1));
    });

    testWidgets('900 px: revisão mantém uma coluna centralizada', (
      tester,
    ) async {
      await pumpCreate(tester, size: sizes['900']!);
      await goToReview(tester);
      final card = tester.getRect(byKeyName('create-edit-name'));
      expect(card.right, lessThanOrEqualTo(450 + createQueueMaxWidth / 2));
      final submit = tester.getRect(byKeyName('create-submit'));
      expect(submit.width, lessThanOrEqualTo(createQueueMaxWidth));
      expect(submit.center.dx, closeTo(450, 1));
    });

    testWidgets('320 px: conteúdo usa a largura com margem de 20', (
      tester,
    ) async {
      await pumpCreate(tester, size: sizes['320']!);
      final field = tester.getRect(byKeyName('create-name'));
      expect(field.left, closeTo(20, 1));
      expect(field.right, closeTo(300, 1));
      final button = tester.getRect(byKeyName('create-continue'));
      expect(button.left, closeTo(20, 1));
      expect(button.right, closeTo(300, 1));
    });
  });

  group('20 horários com teclado', () {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('320 px, teclado aberto, texto ${scale}x', (tester) async {
        await pumpCreate(
          tester,
          size: const Size(320, 640),
          textScale: scale,
          draftStore: twentySlotsStore(),
          uid: 'u1',
        );
        await tester.pumpAndSettle();
        await tapKey(tester, 'create-resume-continue');
        tester.view.viewInsets = const FakeViewPadding(bottom: 260);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.delete_outline), findsNWidgets(20));
        expect(tester.takeException(), isNull);
        final bottom = tester.getBottomLeft(byKeyName('create-continue')).dy;
        expect(bottom, lessThanOrEqualTo(640 - 260));

        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -2000),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
