import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_slot.dart';
import 'package:qio_app/services/manual_entry_service.dart';
import 'package:qio_app/widgets/queue_panel/add_person_dialog.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

Future<void> open(
  WidgetTester tester,
  FakeManualEntryService service, {
  bool scheduled = false,
  List<QueueSlot> slots = const [],
  void Function(ManualAddResult?)? onResult,
}) async {
  await pumpApp(
    tester,
    Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            final r = await showAddPersonDialog(
              context,
              queueId: 'q1',
              service: service,
              scheduled: scheduled,
              slots: slots,
            );
            onResult?.call(r);
          },
          child: const Text('abrir'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('nome vazio mostra erro e não chama o serviço', (tester) async {
    final service = FakeManualEntryService();
    await open(tester, service);
    await tester.tap(find.text('Adicionar'));
    await tester.pump();
    expect(find.text('Informe um nome com até 60 caracteres'), findsOneWidget);
    expect(service.calls, isEmpty);
  });

  testWidgets('telefone incompleto é recusado e a máscara é aplicada', (
    tester,
  ) async {
    final service = FakeManualEntryService();
    await open(tester, service);
    await tester.enterText(find.byType(TextField).first, 'Maria');
    await tester.enterText(find.byType(TextField).last, '1191234');
    await tester.pump();
    expect(find.text('(11) 9123-4'), findsOneWidget);
    await tester.tap(find.text('Adicionar'));
    await tester.pump();
    expect(find.text('Use o formato (00) 00000-0000'), findsOneWidget);
    expect(service.calls, isEmpty);
  });

  testWidgets('envia nome e telefone e devolve o resultado', (tester) async {
    final service = FakeManualEntryService(ticket: 12);
    ManualAddResult? result;
    await open(tester, service, onResult: (r) => result = r);
    await tester.enterText(find.byType(TextField).first, '  Maria  ');
    await tester.enterText(find.byType(TextField).last, '11912345678');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    expect(service.calls.single, {
      'queueId': 'q1',
      'name': 'Maria',
      'phone': '(11) 91234-5678',
      'slotId': null,
    });
    expect(result?.ticket, 12);
    expect(result?.name, 'Maria');
    expect(find.text('Adicionar pessoa à fila'), findsNothing);
  });

  testWidgets('telefone é opcional', (tester) async {
    final service = FakeManualEntryService();
    await open(tester, service);
    await tester.enterText(find.byType(TextField).first, 'Maria');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    expect(service.calls.single['phone'], '');
  });

  testWidgets('fila lotada mostra o erro e mantém o diálogo', (tester) async {
    final service = FakeManualEntryService(
      error: const ManualEntryException(ManualEntryError.queueFull),
    );
    await open(tester, service);
    await tester.enterText(find.byType(TextField).first, 'Maria');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    expect(find.text('A fila está lotada no momento.'), findsOneWidget);
    expect(find.text('Adicionar pessoa à fila'), findsOneWidget);
  });

  testWidgets('telefone duplicado e rate limit mostram a mensagem própria', (
    tester,
  ) async {
    final service = FakeManualEntryService(
      error: const ManualEntryException(ManualEntryError.phoneDuplicate),
    );
    await open(tester, service);
    await tester.enterText(find.byType(TextField).first, 'Maria');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    expect(find.text('Este telefone já está na fila.'), findsOneWidget);
    service.error = const ManualEntryException(ManualEntryError.rateLimited);
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Muitas adições em pouco tempo. Aguarde alguns minutos.'),
      findsOneWidget,
    );
  });

  testWidgets('durante a chamada não fecha por toque fora nem por voltar', (
    tester,
  ) async {
    final gate = Completer<void>();
    final service = FakeManualEntryService(ticket: 3)..gate = gate.future;
    ManualAddResult? result;
    await open(tester, service, onResult: (r) => result = r);
    await tester.enterText(find.byType(TextField).first, 'Maria');
    await tester.tap(find.text('Adicionar'));
    await tester.pump();
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    expect(find.text('Adicionar pessoa à fila'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Adicionar pessoa à fila'), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);
    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Adicionar pessoa à fila'), findsNothing);
    expect(result?.ticket, 3);
  });

  testWidgets('horário lotado usa a mensagem de slot-full', (tester) async {
    final service = FakeManualEntryService(
      error: const ManualEntryException(ManualEntryError.slotFull),
    );
    await open(tester, service);
    await tester.enterText(find.byType(TextField).first, 'Maria');
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    expect(find.text('Este horário está lotado.'), findsOneWidget);
  });

  testWidgets('fila por horário exige escolher o slot', (tester) async {
    final service = FakeManualEntryService();
    await open(
      tester,
      service,
      scheduled: true,
      slots: const [
        QueueSlot(id: 's1', start: '09:00', capacity: 2),
        QueueSlot(id: 's2', start: '10:00', capacity: 3),
      ],
    );
    await tester.enterText(find.byType(TextField).first, 'Maria');
    await tester.tap(find.text('Adicionar'));
    await tester.pump();
    expect(find.text('Escolha um horário'), findsOneWidget);
    expect(service.calls, isEmpty);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10:00 (3 vagas)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();
    expect(service.calls.single['slotId'], 's2');
  });
}
