import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/auth_errors.dart';

void main() {
  group('authErrorMessage', () {
    test('wrong credentials share one message', () {
      for (final code in [
        'invalid-credential',
        'wrong-password',
        'user-not-found',
      ]) {
        expect(authErrorMessage(code), 'E-mail ou senha incorretos.');
      }
    });

    test('maps sign-up errors', () {
      expect(
        authErrorMessage('email-already-in-use'),
        'Já existe uma conta com este e-mail.',
      );
      expect(
        authErrorMessage('weak-password'),
        'Senha fraca. Use pelo menos 6 caracteres.',
      );
    });

    test('unknown code falls back to generic message', () {
      expect(
        authErrorMessage('qualquer'),
        'Não foi possível entrar. Tente novamente.',
      );
      expect(authErrorMessage(''), 'Não foi possível entrar. Tente novamente.');
    });
  });
}
