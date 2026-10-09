import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/alerts_config.dart';
import 'package:qio_app/screens/create_queue_screen.dart';

import '../helpers/create_queue_flow.dart';
import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

Future<void> goToAlerts(WidgetTester tester) async {
  await typeName(tester, 'Clínica');
  await continueSteps(tester, 5);
}

void main() {
  group('passo Alertas', () {
    testWidgets('opcional, com nota de push e Pular', (tester) async {
      await pumpCreate(tester);
      await goToAlerts(tester);
      expect(find.text('Quer receber alertas desta fila?'), findsOneWidget);
      expect(byKeyName('create-alerts-push-note'), findsOneWidget);
      expect(byKeyName('create-skip'), findsOneWidget);
      expect(find.text('Passo 6 de 7'), findsNothing);
      expect(byKeyName('alerts-wait'), findsNothing);
    });

    testWidgets('ativar sem regra bloqueia, com regra libera', (tester) async {
      await pumpCreate(tester);
      await goToAlerts(tester);
      await tapKey(tester, 'alerts-enabled');
      expect(byKeyName('alerts-no-rule'), findsOneWidget);
      await tapKey(tester, 'create-continue');
      expect(byKeyName('create-continue'), findsOneWidget);
      expect(byKeyName('create-submit'), findsNothing);
      await tapKey(tester, 'alerts-wait');
      expect(byKeyName('alerts-no-rule'), findsNothing);
      await tapKey(tester, 'create-continue');
      expect(byKeyName('create-submit'), findsOneWidget);
    });

    testWidgets('fluxo completo: revisão mostra alertas, Editar e create', (
      tester,
    ) async {
      final queues = await pumpCreate(tester);
      await goToAlerts(tester);
      await tapKey(tester, 'alerts-enabled');
      await tapKey(tester, 'alerts-wait');
      await tapKey(tester, 'alerts-idle');
      await tapKey(tester, 'create-continue');

      expect(byKeyName('create-edit-alerts'), findsOneWidget);
      expect(find.text('Alertas'), findsOneWidget);
      expect(find.text('Espera estimada acima de 30 min'), findsOneWidget);
      expect(
        find.text('Fila parada com gente esperando por mais de 15 min'),
        findsOneWidget,
      );

      await tapKey(tester, 'create-edit-alerts');
      expect(byKeyName('create-alerts'), findsOneWidget);
      await tapKey(tester, 'alerts-idle');
      await tapKey(tester, 'create-continue');
      expect(byKeyName('create-submit'), findsOneWidget);

      await tapKey(tester, 'create-submit');
      final alerts = queues.createdAlerts!;
      expect(alerts.enabled, isTrue);
      expect(alerts.maxWaitMin, 30);
      expect(alerts.idleMin, isNull);
      expect(alerts.maxNoShowPct, isNull);
      expect(alerts.cooldownMin, AlertsConfig.defaultCooldownMin);
    });

    testWidgets('pular não envia alerts e a revisão mostra Desligado', (
      tester,
    ) async {
      final queues = await pumpCreate(tester);
      await goToAlerts(tester);
      await tapKey(tester, 'create-skip');
      expect(find.text('Desligado'), findsOneWidget);
      await tapKey(tester, 'create-submit');
      expect(queues.createdAlerts, isNull);
    });

    testWidgets('desligar de novo limpa os alertas', (tester) async {
      final queues = await pumpCreate(tester);
      await goToAlerts(tester);
      await tapKey(tester, 'alerts-enabled');
      await tapKey(tester, 'alerts-wait');
      await tapKey(tester, 'alerts-enabled');
      await tapKey(tester, 'create-continue');
      await tapKey(tester, 'create-submit');
      expect(queues.createdAlerts, isNull);
    });

    for (final size in const [Size(320, 568), Size(390, 844), Size(900, 800)]) {
      for (final scale in const [1.3, 2.0]) {
        testWidgets(
          'layout ${size.width.toInt()} px com texto ${scale}x sem overflow',
          (tester) async {
            await pumpApp(
              tester,
              Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: CreateQueueScreen(
                    queues: FakeQueueService(),
                    groups: FakeGroupService(),
                  ),
                ),
              ),
              size: size,
            );
            await tester.pumpAndSettle();
            await goToAlerts(tester);
            await tapKey(tester, 'alerts-enabled');
            await tapKey(tester, 'alerts-wait');
            await tapKey(tester, 'alerts-noshow');
            await tapKey(tester, 'alerts-idle');
            expect(byKeyName('create-continue'), findsOneWidget);
            expect(tester.takeException(), isNull);
            await tapKey(tester, 'create-continue');
            expect(byKeyName('create-submit'), findsOneWidget);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });
}
