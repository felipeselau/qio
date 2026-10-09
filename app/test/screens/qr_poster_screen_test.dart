import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/screens/qr_poster_screen.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

Future<FakeQueueService> pumpPoster(
  WidgetTester tester, {
  bool canEdit = true,
  String? posterTitle,
  String? brandColor,
  Locale locale = const Locale('pt'),
}) async {
  final service = FakeQueueService();
  await pumpApp(
    tester,
    QrPosterScreen(
      queueName: 'Padaria',
      joinUrl: 'https://qio.web.app/n/padaria',
      queueId: 'q1',
      canEdit: canEdit,
      posterTitle: posterTitle,
      brandColor: brandColor,
      queues: service,
    ),
    locale: locale,
    size: const Size(390, 1400),
  );
  return service;
}

void main() {
  testWidgets('mostra os três tamanhos e o link curto', (tester) async {
    await pumpPoster(tester);
    expect(find.text('A4'), findsOneWidget);
    expect(find.text('A5'), findsOneWidget);
    expect(find.text('Cartão de mesa (10×15 cm)'), findsOneWidget);
    expect(find.text('qio.web.app/n/padaria'), findsOneWidget);
    expect(find.text('Padaria'), findsOneWidget);
  });

  testWidgets('trocar o tamanho muda a proporção da prévia', (tester) async {
    await pumpPoster(tester);
    final before = tester.getSize(find.byType(AspectRatio).first);
    await tester.tap(find.text('Cartão de mesa (10×15 cm)'));
    await tester.pumpAndSettle();
    final after = tester.getSize(find.byType(AspectRatio).first);
    expect(after.height / after.width, closeTo(1.5, 0.01));
    expect(before.height / before.width, closeTo(1.414, 0.01));
  });

  testWidgets('instruções nos três idiomas na prévia', (tester) async {
    await pumpPoster(tester);
    expect(find.text('Escaneie para entrar na fila'), findsOneWidget);
    expect(find.textContaining('Scan to join the queue'), findsOneWidget);
  });

  testWidgets('frase aparece na prévia e respeita 60 caracteres', (
    tester,
  ) async {
    await pumpPoster(tester, posterTitle: 'Peça seu lugar');
    expect(find.text('Peça seu lugar'), findsWidgets);
    await tester.enterText(find.byType(TextFormField), 'a' * 61);
    await tester.pump();
    await tester.tap(find.text('Imprimir'));
    await tester.pumpAndSettle();
    expect(find.text('Use até 60 caracteres.'), findsOneWidget);
  });

  testWidgets('sem permissão de edição não mostra o campo de frase', (
    tester,
  ) async {
    await pumpPoster(tester, canEdit: false);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('prévia tem rótulo de acessibilidade com o tamanho', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpPoster(tester);
    expect(find.bySemanticsLabel('Prévia do cartaz em A4'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('em inglês usa rótulos traduzidos', (tester) async {
    await pumpPoster(tester, locale: const Locale('en'));
    expect(find.text('Table card (10×15 cm)'), findsOneWidget);
    expect(find.text('Share PDF'), findsOneWidget);
  });
}
