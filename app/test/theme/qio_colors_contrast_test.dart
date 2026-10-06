import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/theme/qio_colors.dart';

double _channel(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

Color _tint(Color fg, Color bg, [double alpha = 0.12]) =>
    Color.alphaBlend(fg.withValues(alpha: alpha), bg);

void main() {
  tearDown(() => QioColors.apply(Brightness.light));

  for (final brightness in Brightness.values) {
    group('contrast ${brightness.name}', () {
      setUp(() => QioColors.apply(brightness));

      void expectAa(String name, Color fg, Color bg, [double min = 4.5]) {
        final ratio = contrast(fg, bg);
        expect(
          ratio,
          greaterThanOrEqualTo(min),
          reason: '$name ${ratio.toStringAsFixed(2)}:1 < $min:1',
        );
      }

      test('text on surfaces', () {
        for (final bg in [
          QioColors.background,
          QioColors.surface,
          QioColors.card,
          QioColors.gray100,
        ]) {
          expectAa('textPrimary', QioColors.textPrimary, bg);
          expectAa('textSecondary', QioColors.textSecondary, bg);
          expectAa('textHint', QioColors.textHint, bg);
          expectAa('gray400', QioColors.gray400, bg);
          expectAa('gray500', QioColors.gray500, bg);
          expectAa('gray700', QioColors.gray700, bg);
          expectAa('primaryText', QioColors.primaryText, bg);
        }
      });

      test('status text on tinted backgrounds', () {
        for (final bg in [QioColors.surface, QioColors.card]) {
          expectAa(
            'open',
            QioColors.statusOpenText,
            _tint(QioColors.statusOpen, bg),
          );
          expectAa(
            'paused',
            QioColors.statusPausedText,
            _tint(QioColors.statusPaused, bg),
          );
          expectAa(
            'closed',
            QioColors.statusClosedText,
            _tint(QioColors.statusClosed, bg),
          );
        }
      });

      test('filled buttons with white text', () {
        expectAa('primary', Colors.white, QioColors.primary);
        expectAa('danger', Colors.white, QioColors.dangerStrong);
        expectAa('success', Colors.white, QioColors.successStrong);
      });
    });
  }
}
