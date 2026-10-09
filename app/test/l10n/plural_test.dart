import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/l10n/app_localizations.dart';

void main() {
  const expected = {
    'pt': ('1 pessoa', '3 pessoas', '1 horário', '3 horários'),
    'en': ('1 person', '3 people', '1 time slot', '3 time slots'),
    'es': ('1 persona', '3 personas', '1 horario', '3 horarios'),
  };

  for (final entry in expected.entries) {
    test('plural de pessoas e horários em ${entry.key}', () {
      final l10n = lookupAppLocalizations(Locale(entry.key));
      expect(l10n.cqLimitPeople(1), entry.value.$1);
      expect(l10n.cqLimitPeople(3), entry.value.$2);
      expect(l10n.slotsTileSummary(1), entry.value.$3);
      expect(l10n.slotsTileSummary(3), entry.value.$4);
    });
  }
}
