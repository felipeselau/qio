import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/resilient_stream.dart';

FirebaseException denied() =>
    FirebaseException(plugin: 'firebase_database', code: 'permission-denied');

void main() {
  test('reanexa depois de permission-denied e entrega o proximo valor', () {
    fakeAsync((async) {
      var opens = 0;
      final values = <int>[];
      final errors = <Object>[];
      retryOnPermissionDenied<int>(() {
        opens++;
        return opens == 1 ? Stream<int>.error(denied()) : Stream.value(opens);
      }).listen(values.add, onError: errors.add);
      async.flushMicrotasks();
      expect(opens, 1);
      async.elapse(const Duration(seconds: 3));
      expect(opens, 2);
      expect(values, [2]);
      expect(errors, isEmpty);
    });
  });

  test('desiste depois de 5 tentativas e repassa o erro', () {
    fakeAsync((async) {
      var opens = 0;
      final errors = <Object>[];
      retryOnPermissionDenied<int>(() {
        opens++;
        return Stream<int>.error(denied());
      }).listen((_) {}, onError: errors.add);
      async.elapse(const Duration(seconds: 30));
      expect(opens, 6);
      expect(errors, hasLength(1));
    });
  });

  test('outros erros passam direto sem retry', () {
    fakeAsync((async) {
      var opens = 0;
      final errors = <Object>[];
      retryOnPermissionDenied<int>(() {
        opens++;
        return Stream<int>.error(StateError('x'));
      }).listen((_) {}, onError: errors.add);
      async.elapse(const Duration(seconds: 10));
      expect(opens, 1);
      expect(errors, hasLength(1));
    });
  });
}
