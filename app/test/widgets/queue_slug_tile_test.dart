import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/queue_service.dart';
import 'package:qio_app/widgets/queue_panel/queue_slug_tile.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

Future<FakeQueueService> open(
  WidgetTester tester, {
  String? slug,
  Object? error,
}) async {
  final service = FakeQueueService()..slugError = error;
  await pumpApp(
    tester,
    Scaffold(
      body: QueueSlugTile(queueId: 'q1', slug: slug, queues: service),
    ),
  );
  await tester.tap(find.byType(QueueSlugTile));
  await tester.pumpAndSettle();
  return service;
}

void main() {
  testWidgets('mostra o link atual no tile', (tester) async {
    final service = FakeQueueService();
    await pumpApp(
      tester,
      Scaffold(
        body: QueueSlugTile(queueId: 'q1', slug: 'padaria', queues: service),
      ),
    );
    expect(find.text('qio.web.app/n/padaria'), findsOneWidget);
  });

  testWidgets('sem slug mostra "Não definido"', (tester) async {
    final service = FakeQueueService();
    await pumpApp(
      tester,
      Scaffold(
        body: QueueSlugTile(queueId: 'q1', slug: null, queues: service),
      ),
    );
    expect(find.text('Não definido'), findsOneWidget);
  });

  testWidgets('aviso de QR impresso só aparece com slug atual', (tester) async {
    await open(tester, slug: 'padaria');
    expect(find.textContaining('30 dias'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
  });

  testWidgets('sem slug atual não mostra o aviso', (tester) async {
    await open(tester);
    expect(find.textContaining('30 dias'), findsNothing);
  });

  testWidgets('formato inválido bloqueia o salvamento', (tester) async {
    final service = await open(tester);
    await tester.enterText(find.byType(TextFormField), 'ab');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('3 a 40'), findsOneWidget);
    expect(service.calls, isEmpty);
  });

  testWidgets('nome reservado é recusado', (tester) async {
    final service = await open(tester);
    await tester.enterText(find.byType(TextFormField), 'privacidade');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.text('Esse nome é reservado. Escolha outro.'), findsOneWidget);
    expect(service.calls, isEmpty);
  });

  testWidgets('salva normalizado e fecha o diálogo', (tester) async {
    final service = await open(tester, slug: 'antigo');
    await tester.enterText(find.byType(TextFormField), '  Minha-Loja ');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(service.calls, ['setSlug:q1:antigo:minha-loja']);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Link curto salvo'), findsOneWidget);
  });

  testWidgets('slug em uso mostra erro e mantém o diálogo', (tester) async {
    final service = await open(tester, error: const SlugTaken());
    await tester.enterText(find.byType(TextFormField), 'padaria');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(service.calls, ['setSlug:q1:-:padaria']);
    expect(
      find.text('Esse link já está em uso. Escolha outro.'),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('remover apaga o slug atual', (tester) async {
    final service = await open(tester, slug: 'padaria');
    await tester.tap(find.text('Remover link curto'));
    await tester.pumpAndSettle();
    expect(service.calls, ['setSlug:q1:padaria:-']);
    expect(find.text('Link curto removido'), findsOneWidget);
  });

  testWidgets('erro genérico aparece no diálogo', (tester) async {
    await open(tester, error: Exception('boom'));
    await tester.enterText(find.byType(TextFormField), 'padaria');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}
