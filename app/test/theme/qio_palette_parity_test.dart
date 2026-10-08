import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/theme/qio_colors.dart';
import 'package:qio_app/theme/qio_palette.dart';

Map<String, Color> _fromColors() => {
  'background': QioColors.background,
  'surface': QioColors.surface,
  'card': QioColors.card,
  'gray50': QioColors.gray50,
  'gray100': QioColors.gray100,
  'gray200': QioColors.gray200,
  'gray300': QioColors.gray300,
  'gray400': QioColors.gray400,
  'gray500': QioColors.gray500,
  'gray600': QioColors.gray600,
  'gray700': QioColors.gray700,
  'gray800': QioColors.gray800,
  'gray900': QioColors.gray900,
  'textPrimary': QioColors.textPrimary,
  'textSecondary': QioColors.textSecondary,
  'textHint': QioColors.textHint,
  'primaryText': QioColors.primaryText,
  'statusOpenText': QioColors.statusOpenText,
  'statusPausedText': QioColors.statusPausedText,
  'statusClosedText': QioColors.statusClosedText,
};

Map<String, Color> _fromPalette(QioPalette p) => {
  'background': p.background,
  'surface': p.surface,
  'card': p.card,
  'gray50': p.gray50,
  'gray100': p.gray100,
  'gray200': p.gray200,
  'gray300': p.gray300,
  'gray400': p.gray400,
  'gray500': p.gray500,
  'gray600': p.gray600,
  'gray700': p.gray700,
  'gray800': p.gray800,
  'gray900': p.gray900,
  'textPrimary': p.textPrimary,
  'textSecondary': p.textSecondary,
  'textHint': p.textHint,
  'primaryText': p.primaryText,
  'statusOpenText': p.statusOpenText,
  'statusPausedText': p.statusPausedText,
  'statusClosedText': p.statusClosedText,
};

void main() {
  tearDown(() => QioColors.apply(Brightness.light));

  for (final b in Brightness.values) {
    test('palette ${b.name} matches QioColors', () {
      QioColors.apply(b);
      final expected = _fromColors();
      final actual = _fromPalette(QioPalette.forBrightness(b));
      expect(actual.length, 20);
      for (final e in expected.entries) {
        expect(actual[e.key], e.value, reason: e.key);
      }
    });
  }

  test('lerp endpoints and copyWith', () {
    final end = QioPalette.light.lerp(QioPalette.dark, 1);
    expect(end.surface, QioPalette.dark.surface);
    expect(QioPalette.light.copyWith(card: Colors.red).card, Colors.red);
  });
}
