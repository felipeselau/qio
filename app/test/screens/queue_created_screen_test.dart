import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/screens/queue_created_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

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

Future<List<String>> pumpCreated(WidgetTester tester) async {
  final shared = <String>[];
  await pumpApp(
    tester,
    QueueCreatedScreen(
      queue: queue,
      queues: FakeQueueService(),
      onShare: (url) async => shared.add(url),
      destinationBuilder: marker,
    ),
    size: const Size(390, 1000),
  );
  return shared;
}

void main() {
  testWidgets('mostra título, nome, QR e link', (tester) async {
    await pumpCreated(tester);
    expect(find.text('Fila criada'), findsOneWidget);
    expect(find.text('Clínica Sol'), findsOneWidget);
    expect(find.text('qio.web.app/q/abc123'), findsOneWidget);
    expect(find.byType(QrImageView), findsOneWidget);
  });

  testWidgets('compartilhar chama o share com o link', (tester) async {
    final shared = await pumpCreated(tester);
    await tapKey(tester, 'created-share');
    expect(shared, ['https://qio.web.app/q/abc123']);
  });

  testWidgets('falha no share mostra erro genérico', (tester) async {
    await pumpApp(
      tester,
      QueueCreatedScreen(
        queue: queue,
        onShare: (_) async => throw Exception('x'),
        destinationBuilder: marker,
      ),
    );
    await tapKey(tester, 'created-share');
    expect(
      find.text('Não foi possível concluir a ação. Tente novamente.'),
      findsOneWidget,
    );
  });

  testWidgets('tocar no link copia', (tester) async {
    final copied = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpCreated(tester);
    await tapKey(tester, 'created-link');
    expect(copied, ['https://qio.web.app/q/abc123']);
    expect(find.text('Link copiado!'), findsOneWidget);
  });

  testWidgets('Abrir painel substitui a tela', (tester) async {
    await pumpCreated(tester);
    await tapKey(tester, 'created-open-panel');
    expect(find.text('dest:panel'), findsOneWidget);
    expect(byKeyName('created-title'), findsNothing);
  });

  for (final (key, target) in [
    ('created-shortcut-logo', 'logo'),
    ('created-shortcut-link', 'shortLink'),
    ('created-shortcut-operators', 'operators'),
    ('created-shortcut-alerts', 'alerts'),
  ]) {
    testWidgets('atalho $target abre o destino e volta', (tester) async {
      await pumpCreated(tester);
      await tapKey(tester, key);
      expect(find.text('dest:$target'), findsOneWidget);
      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(byKeyName('created-title'), findsOneWidget);
    });
  }

  testWidgets('voltar do sistema abre o painel', (tester) async {
    await pumpCreated(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('dest:panel'), findsOneWidget);
    expect(byKeyName('created-title'), findsNothing);
  });

  testWidgets('semântica e áreas de toque', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpCreated(tester);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    handle.dispose();
  });

  testWidgets('criar leva à tela Fila criada sem voltar ao wizard', (
    tester,
  ) async {
    final queues = FakeQueueService()..createResult = queue;
    await pumpCreate(tester, queues: queues);
    await typeName(tester, 'Clínica Sol');
    await tapKey(tester, 'create-quick');
    expect(byKeyName('created-title'), findsOneWidget);
    expect(byKeyName('create-name'), findsNothing);
    expect(queues.calls, ['create:Clínica Sol:queue:0']);
  });
}
