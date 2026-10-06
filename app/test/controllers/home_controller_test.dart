import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/controllers/home_controller.dart';
import 'package:qio_app/models/operator.dart';
import 'package:qio_app/models/queue.dart';

Queue queue(String id) =>
    Queue(id: id, ownerId: 'o', name: 'Fila $id', createdAt: DateTime(2026));

void main() {
  late StreamController<List<Queue>> owned;
  late StreamController<List<QueueOperator>> operating;
  late StreamController<List<OperatorRequest>> requests;
  var subscriptions = 0;

  HomeController build() {
    subscriptions = 0;
    owned = StreamController<List<Queue>>.broadcast();
    operating = StreamController<List<QueueOperator>>.broadcast();
    requests = StreamController<List<OperatorRequest>>.broadcast();
    return HomeController(
      ownedSource: () {
        subscriptions++;
        return owned.stream;
      },
      operatingSource: () => operating.stream,
      requestsSource: () => requests.stream,
    );
  }

  test('starts loading and exposes data per section', () async {
    final c = build();
    expect(c.isLoading, isTrue);
    owned.add([queue('a')]);
    await Future<void>.delayed(Duration.zero);
    expect(c.isLoading, isFalse);
    expect(c.ownedQueues.single.id, 'a');
    expect(c.operatingQueues, isEmpty);
    expect(c.hasError, isFalse);
    c.dispose();
  });

  test('an error in any stream is reported, not treated as empty', () async {
    final c = build();
    owned.add([queue('a')]);
    operating.addError(Exception('denied'));
    await Future<void>.delayed(Duration.zero);
    expect(c.hasError, isTrue);
    expect(c.operating.hasError, isTrue);
    expect(c.owned.hasError, isFalse);
    c.dispose();
  });

  test('retry resubscribes and resets to loading', () async {
    final c = build();
    owned.addError(Exception('x'));
    await Future<void>.delayed(Duration.zero);
    expect(c.hasError, isTrue);
    c.retry();
    expect(c.isLoading, isTrue);
    expect(c.hasError, isFalse);
    expect(subscriptions, 2);
    owned.add([queue('b')]);
    await Future<void>.delayed(Duration.zero);
    expect(c.ownedQueues.single.id, 'b');
    c.dispose();
  });

  test('dispose cancels listeners', () async {
    final c = build();
    c.dispose();
    expect(owned.hasListener, isFalse);
    expect(operating.hasListener, isFalse);
    expect(requests.hasListener, isFalse);
  });
}
