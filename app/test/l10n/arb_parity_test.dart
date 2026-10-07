import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> keys(String locale) =>
    (jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
            as Map<String, dynamic>)
        .keys
        .where((k) => !k.startsWith('@') || k == '@@locale')
        .toSet();

void main() {
  test('pt, en and es ARBs have the same keys', () {
    final pt = keys('pt');
    expect(keys('en'), pt);
    expect(keys('es'), pt);
  });
}
