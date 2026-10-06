import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/l10n/app_localizations.dart';
import 'package:qio_app/services/auth_errors.dart';

void main() {
  final pt = lookupAppLocalizations(const Locale('pt'));
  final en = lookupAppLocalizations(const Locale('en'));
  final es = lookupAppLocalizations(const Locale('es'));

  group('authErrorMessage', () {
    test('wrong credentials share one message', () {
      for (final code in [
        'invalid-credential',
        'wrong-password',
        'user-not-found',
      ]) {
        expect(authErrorMessage(pt, code), 'E-mail ou senha incorretos.');
      }
    });

    test('maps sign-up errors', () {
      expect(
        authErrorMessage(pt, 'email-already-in-use'),
        'Já existe uma conta com este e-mail.',
      );
      expect(
        authErrorMessage(pt, 'weak-password'),
        'Senha fraca. Use pelo menos 6 caracteres.',
      );
    });

    test('unknown code falls back to generic message', () {
      expect(
        authErrorMessage(pt, 'qualquer'),
        'Não foi possível entrar. Tente novamente.',
      );
      expect(
        authErrorMessage(pt, ''),
        'Não foi possível entrar. Tente novamente.',
      );
    });

    test('follows the locale', () {
      expect(authErrorMessage(en, 'invalid-email'), 'Invalid email.');
      expect(
        authErrorMessage(es, 'user-disabled'),
        'Esta cuenta fue desactivada.',
      );
    });
  });
}
