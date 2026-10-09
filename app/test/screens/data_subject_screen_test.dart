import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/screens/data_subject_screen.dart';
import 'package:qio_app/services/data_subject_service.dart';

import '../helpers/fake_auth.dart';
import '../helpers/pump_app.dart';

const tall = Size(390, 1400);

class FakeDataSubjectService extends DataSubjectService {
  FakeDataSubjectService({
    this.summary = const CustomerSummary(queues: []),
    this.findErrors = const [],
    this.eraseResult = const CustomerSummary(queues: []),
  }) : super(invoker: (_, _) async => <String, dynamic>{});

  CustomerSummary summary;
  List<Object> findErrors;
  CustomerSummary eraseResult;
  final List<String> calls = [];
  int findCount = 0;

  @override
  Future<CustomerSummary> find(String phoneDigits) async {
    calls.add('find:$phoneDigits');
    if (findCount < findErrors.length) throw findErrors[findCount++];
    return summary;
  }

  @override
  Future<CustomerExport> export(String phoneDigits) async {
    calls.add('export:$phoneDigits');
    return const CustomerExport(csv: 'queue,name\nq,Ana', truncated: false);
  }

  @override
  Future<CustomerSummary> erase(
    String phoneDigits,
    CustomerEraseMode mode,
  ) async {
    calls.add('erase:$phoneDigits:${mode.name}');
    return eraseResult;
  }
}

const found = CustomerSummary(
  queues: [
    CustomerQueueData(
      queueId: 'q1',
      queueName: 'Balcão',
      history: 2,
      feedback: 1,
      entries: 1,
    ),
  ],
);

Future<void> search(WidgetTester tester, String phone) async {
  await tester.enterText(find.byType(TextField).first, phone);
  await tester.pump();
  await tester.tap(find.text('Buscar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('search stays disabled until the phone is valid', (tester) async {
    final service = FakeDataSubjectService();
    await pumpApp(tester, DataSubjectScreen(service: service), size: tall);
    await tester.enterText(find.byType(TextField).first, '1199');
    await tester.pump();
    await tester.tap(find.text('Buscar'));
    await tester.pump();
    expect(service.calls, isEmpty);
  });

  testWidgets('masks the phone and lists counts per queue', (tester) async {
    final service = FakeDataSubjectService(summary: found);
    await pumpApp(tester, DataSubjectScreen(service: service), size: tall);
    await search(tester, '11999999999');
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      '(11) 99999-9999',
    );
    expect(service.calls, ['find:11999999999']);
    expect(find.text('Encontrado em 1 fila(s)'), findsOneWidget);
    expect(find.text('Balcão'), findsOneWidget);
    expect(
      find.text('2 no histórico, 1 avaliações, 1 na fila agora'),
      findsOneWidget,
    );
    expect(find.text('Excluir'), findsOneWidget);
    expect(find.text('Anonimizar'), findsOneWidget);
  });

  testWidgets('shows an empty state without action buttons', (tester) async {
    await pumpApp(
      tester,
      DataSubjectScreen(service: FakeDataSubjectService()),
      size: tall,
    );
    await search(tester, '11999999999');
    expect(
      find.text('Nenhum dado encontrado para este telefone nas suas filas.'),
      findsOneWidget,
    );
    expect(find.text('Excluir'), findsNothing);
  });

  testWidgets('export shares the csv', (tester) async {
    final service = FakeDataSubjectService(summary: found);
    final shared = <(String, String)>[];
    await pumpApp(
      tester,
      DataSubjectScreen(
        service: service,
        shareCsv: (csv, name) async => shared.add((csv, name)),
      ),
      size: tall,
    );
    await search(tester, '11999999999');
    await tester.tap(find.text('Exportar dados (CSV)'));
    await tester.pumpAndSettle();
    expect(service.calls.last, 'export:11999999999');
    expect(shared.single.$1, contains('Ana'));
  });

  testWidgets('erase needs the phone typed again', (tester) async {
    final service = FakeDataSubjectService(summary: found, eraseResult: found);
    await pumpApp(tester, DataSubjectScreen(service: service), size: tall);
    await search(tester, '11999999999');
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    expect(find.text('Excluir dados deste cliente?'), findsOneWidget);

    final confirm = find.widgetWithText(TextButton, 'Confirmar');
    expect(tester.widget<TextButton>(confirm).onPressed, isNull);

    await tester.enterText(find.byType(TextField).last, '11988888888');
    await tester.pump();
    expect(tester.widget<TextButton>(confirm).onPressed, isNull);

    await tester.enterText(find.byType(TextField).last, '(11) 99999-9999');
    await tester.pump();
    expect(tester.widget<TextButton>(confirm).onPressed, isNotNull);
    await tester.tap(confirm);
    await tester.pumpAndSettle();

    expect(service.calls.last, 'erase:11999999999:delete');
    expect(find.text('Concluído: 4 registro(s) tratado(s).'), findsOneWidget);
    expect(find.text('Balcão'), findsNothing);
  });

  testWidgets('anonymize uses its own mode and cancel does nothing', (
    tester,
  ) async {
    final service = FakeDataSubjectService(summary: found, eraseResult: found);
    await pumpApp(tester, DataSubjectScreen(service: service), size: tall);
    await search(tester, '11999999999');
    await tester.tap(find.text('Anonimizar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(service.calls, ['find:11999999999']);

    await tester.tap(find.text('Anonimizar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '11999999999');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Confirmar'));
    await tester.pumpAndSettle();
    expect(service.calls.last, 'erase:11999999999:anonymize');
  });

  testWidgets('partial erase warns the owner', (tester) async {
    final service = FakeDataSubjectService(
      summary: found,
      eraseResult: const CustomerSummary(queues: [], complete: false),
    );
    await pumpApp(tester, DataSubjectScreen(service: service), size: tall);
    await search(tester, '11999999999');
    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '11999999999');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Confirmar'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Alguns registros não foram tratados. Busque de novo e tente outra vez.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('rate limit shows its own message', (tester) async {
    final service = FakeDataSubjectService(
      findErrors: [
        FirebaseException(
          plugin: 'cloud_functions',
          code: 'resource-exhausted',
        ),
      ],
    );
    await pumpApp(tester, DataSubjectScreen(service: service), size: tall);
    await search(tester, '11999999999');
    expect(
      find.text('Muitas consultas seguidas. Aguarde um pouco e tente de novo.'),
      findsOneWidget,
    );
  });

  testWidgets('recent-login asks for the password and retries', (tester) async {
    final auth = FakeAuthService(user: FakeUser());
    final service = FakeDataSubjectService(
      summary: found,
      findErrors: [
        FirebaseException(plugin: 'cloud_functions', code: 'recent-login'),
      ],
    );
    await pumpApp(
      tester,
      DataSubjectScreen(service: service, auth: auth),
      size: tall,
    );
    await tester.enterText(find.byType(TextField).first, '11999999999');
    await tester.pump();
    await tester.tap(find.text('Buscar'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Confirme sua identidade'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'segredo');
    await tester.pump();
    await tester.tap(find.text('Confirmar identidade'));
    await tester.pumpAndSettle();
    expect(auth.calls, contains('reauth:password:segredo'));
    expect(service.calls, ['find:11999999999', 'find:11999999999']);
    expect(find.text('Balcão'), findsOneWidget);
  });

  testWidgets('has accessible labels', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      DataSubjectScreen(service: FakeDataSubjectService(summary: found)),
      size: tall,
    );
    await search(tester, '11999999999');
    expect(find.bySemanticsLabel('Telefone do cliente'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Encontrado em 1')), findsOneWidget);
    handle.dispose();
  });
}
