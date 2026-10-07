import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/alerts_config.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/services/push_service.dart';

void main() {
  test('fromMap returns null for non-map', () {
    expect(AlertsConfig.fromMap(null), isNull);
    expect(AlertsConfig.fromMap('x'), isNull);
  });

  test('fromMap parses limits and defaults cooldown', () {
    final c = AlertsConfig.fromMap({
      'enabled': true,
      'maxWaitMin': 30,
      'maxNoShowPct': 40.0,
    })!;
    expect(c.enabled, isTrue);
    expect(c.maxWaitMin, 30);
    expect(c.maxNoShowPct, 40);
    expect(c.idleMin, isNull);
    expect(c.cooldownMin, 30);
    expect(c.activeRules, 2);
  });

  test('fromMap drops out-of-range limits', () {
    final c = AlertsConfig.fromMap({
      'enabled': true,
      'maxWaitMin': 999,
      'maxNoShowPct': 0,
      'idleMin': 4,
      'cooldownMin': 1,
    })!;
    expect(c.activeRules, 0);
    expect(c.cooldownMin, AlertsConfig.defaultCooldownMin);
  });

  test('toMap omits null limits and round trips', () {
    const c = AlertsConfig(enabled: true, maxWaitMin: 20, cooldownMin: 60);
    final map = c.toMap();
    expect(map, {'enabled': true, 'maxWaitMin': 20, 'cooldownMin': 60});
    final back = AlertsConfig.fromMap(map)!;
    expect(back.maxWaitMin, 20);
    expect(back.cooldownMin, 60);
    expect(back.idleMin, isNull);
  });

  test('copyWith can clear a limit', () {
    const c = AlertsConfig(enabled: true, idleMin: 15);
    final cleared = c.copyWith(idleMin: () => null);
    expect(cleared.idleMin, isNull);
    expect(cleared.enabled, isTrue);
  });

  test('Queue.fromDoc reads alerts', () {
    final q = Queue.fromDoc('q', {
      'ownerId': 'o',
      'name': 'n',
      'alerts': {'enabled': true, 'idleMin': 10},
    });
    expect(q.alerts?.idleMin, 10);
    expect(Queue.fromDoc('q', {'ownerId': 'o'}).alerts, isNull);
  });

  test('queueIdFromPush reads queueId for queue-alert', () {
    expect(queueIdFromPush({'type': alertPushType, 'queueId': 'q1'}), 'q1');
    expect(queueIdFromPush({'queueId': ''}), isNull);
    expect(queueIdFromPush({}), isNull);
  });
}
