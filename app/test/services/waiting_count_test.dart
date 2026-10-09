import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/waiting_count.dart';

void main() {
  group('countWaitingPublic', () {
    test('conta só waiting', () {
      expect(
        countWaitingPublic({
          'a': {'status': 'waiting', 'ticket': 1},
          'b': {'status': 'called', 'ticket': 2},
          'c': {'status': 'waiting', 'ticket': 3},
        }),
        2,
      );
    });

    test('nulo ou formato inválido vira 0', () {
      expect(countWaitingPublic(null), 0);
      expect(countWaitingPublic('x'), 0);
      expect(countWaitingPublic({'a': 1}), 0);
    });
  });

  group('waitingCountStream', () {
    late StreamController<Object?> meta;
    late StreamController<Object?> pub;
    late int publicListens;
    late int publicCancels;

    setUp(() {
      meta = StreamController<Object?>();
      pub = StreamController<Object?>();
      publicListens = 0;
      publicCancels = 0;
    });

    test('usa o contador do meta e não abre public', () async {
      final values = <int>[];
      final sub = waitingCountStream(
        metaCount: meta.stream,
        publicNode: () {
          publicListens++;
          return pub.stream;
        },
      ).listen(values.add);
      meta.add(3);
      meta.add(4);
      await pumpEventQueue();
      expect(values, [3, 4]);
      expect(publicListens, 0);
      await sub.cancel();
    });

    test('meta ausente cai para a contagem por public', () async {
      final values = <int>[];
      final sub = waitingCountStream(
        metaCount: meta.stream,
        publicNode: () {
          publicListens++;
          return pub.stream;
        },
      ).listen(values.add);
      meta.add(null);
      await pumpEventQueue();
      pub.add({
        'a': {'status': 'waiting'},
        'b': {'status': 'waiting'},
      });
      await pumpEventQueue();
      meta.add(null);
      await pumpEventQueue();
      expect(values, [2]);
      expect(publicListens, 1);
      await sub.cancel();
    });

    test('quando o meta passa a existir, abandona o public', () async {
      final values = <int>[];
      final fallback = StreamController<Object?>(
        onCancel: () => publicCancels++,
      );
      final sub = waitingCountStream(
        metaCount: meta.stream,
        publicNode: () => fallback.stream,
      ).listen(values.add);
      meta.add(null);
      await pumpEventQueue();
      fallback.add({
        'a': {'status': 'waiting'},
      });
      await pumpEventQueue();
      meta.add(0);
      await pumpEventQueue();
      expect(values, [1, 0]);
      expect(publicCancels, 1);
      await sub.cancel();
    });

    test(
      'campo ausente, presente e ausente de novo troca de listener',
      () async {
        var listens = 0;
        var cancels = 0;
        late StreamController<Object?> fallback;
        final values = <int>[];
        final sub = waitingCountStream(
          metaCount: meta.stream,
          publicNode: () {
            listens++;
            fallback = StreamController<Object?>(onCancel: () => cancels++);
            return fallback.stream;
          },
        ).listen(values.add);
        meta.add(null);
        await pumpEventQueue();
        fallback.add({
          'a': {'status': 'waiting'},
        });
        await pumpEventQueue();
        meta.add(5);
        await pumpEventQueue();
        meta.add(null);
        await pumpEventQueue();
        fallback.add({
          'a': {'status': 'waiting'},
          'b': {'status': 'waiting'},
        });
        await pumpEventQueue();
        expect(values, [1, 5, 2]);
        expect(listens, 2);
        expect(cancels, 1);
        await sub.cancel();
        expect(cancels, 2);
      },
    );

    test('cancelar encerra meta e public', () async {
      var metaCancelled = false;
      final m = StreamController<Object?>(onCancel: () => metaCancelled = true);
      final fallback = StreamController<Object?>(
        onCancel: () => publicCancels++,
      );
      final sub = waitingCountStream(
        metaCount: m.stream,
        publicNode: () => fallback.stream,
      ).listen((_) {});
      m.add(null);
      await pumpEventQueue();
      await sub.cancel();
      expect(metaCancelled, isTrue);
      expect(publicCancels, 1);
    });
  });
}
