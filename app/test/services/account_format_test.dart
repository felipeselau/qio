import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/account_format.dart';

void main() {
  group('initialsOf', () {
    test('nome simples', () => expect(initialsOf('Ana'), 'A'));
    test('nome composto', () => expect(initialsOf('Ana Souza'), 'AS'));
    test('mais de dois nomes usa os dois primeiros', () {
      expect(initialsOf('Ana Maria Souza'), 'AM');
    });
    test('espaços extras', () => expect(initialsOf('  ana   souza  '), 'AS'));
    test('vazio', () {
      expect(initialsOf(''), 'Q');
      expect(initialsOf('   '), 'Q');
    });
    test('minúsculas', () => expect(initialsOf('joão silva'), 'JS'));
  });

  group('formatMemberSince', () {
    test('zero à esquerda', () {
      expect(formatMemberSince(DateTime(2025, 3, 5)), '05/03/2025');
    });
    test('dia e mês com dois dígitos', () {
      expect(formatMemberSince(DateTime(2024, 12, 31)), '31/12/2024');
    });
  });
}
