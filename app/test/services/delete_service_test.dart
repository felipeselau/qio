import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/action_errors.dart';
import 'package:qio_app/services/delete_service.dart';

void main() {
  group('deleteConfirmationMatches', () {
    test('aceita a palavra nos três idiomas e o e-mail', () {
      expect(deleteConfirmationMatches('EXCLUIR'), isTrue);
      expect(deleteConfirmationMatches(' delete '), isTrue);
      expect(deleteConfirmationMatches('Eliminar'), isTrue);
      expect(
        deleteConfirmationMatches('Dono@Qio.app', email: 'dono@qio.app'),
        isTrue,
      );
    });

    test('recusa vazio, texto errado e e-mail ausente', () {
      expect(deleteConfirmationMatches(''), isFalse);
      expect(deleteConfirmationMatches('sim'), isFalse);
      expect(deleteConfirmationMatches('x@y.z'), isFalse);
      expect(deleteConfirmationMatches('x@y.z', email: ''), isFalse);
    });
  });

  group('DeleteService', () {
    test('deleteQueue chama a callable com o queueId', () async {
      final calls = <(String, Map<String, dynamic>)>[];
      final service = DeleteService(
        invoker: (name, data) async {
          calls.add((name, data));
          return {'ok': true};
        },
      );
      await service.deleteQueue('q1');
      expect(calls.single.$1, 'deleteQueue');
      expect(calls.single.$2, {'queueId': 'q1'});
    });

    test('deleteAccount chama a callable sem argumentos', () async {
      String? called;
      final service = DeleteService(
        invoker: (name, data) async {
          called = name;
          return {};
        },
      );
      await service.deleteAccount();
      expect(called, 'deleteAccount');
    });

    test('erros da callable viram FirebaseException tratável', () async {
      for (final (code, expected) in [
        ('unavailable', ActionError.offline),
        ('permission-denied', ActionError.accessEnded),
        ('unauthenticated', ActionError.accessEnded),
        ('failed-precondition', ActionError.generic),
      ]) {
        final service = DeleteService(
          invoker: (_, _) async =>
              throw FirebaseFunctionsException(message: 'x', code: code),
        );
        await expectLater(
          service.deleteQueue('q1'),
          throwsA(
            isA<FirebaseException>()
                .having((e) => e.code, 'code', code)
                .having((e) => describeActionError(e), 'action', expected),
          ),
        );
      }
    });

    test('aborted com reason partial vira delete-incomplete', () {
      final mapped = mapCallableError(
        FirebaseFunctionsException(
          message: 'x',
          code: 'aborted',
          details: {'reason': 'partial'},
        ),
      );
      expect(mapped.code, 'delete-incomplete');
    });
  });
}
