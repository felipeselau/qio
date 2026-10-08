import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/theme/qio_colors.dart';
import 'package:qio_app/theme/qio_palette.dart';

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
  for (final brightness in Brightness.values) {
    group('contrast ${brightness.name}', () {
      final p = QioPalette.forBrightness(brightness);

      void expectAa(String name, Color fg, Color bg, [double min = 4.5]) {
        final ratio = contrast(fg, bg);
        expect(
          ratio,
          greaterThanOrEqualTo(min),
          reason: '$name ${ratio.toStringAsFixed(2)}:1 < $min:1',
        );
      }

      test('text on surfaces', () {
        for (final bg in [p.background, p.surface, p.card, p.gray100]) {
          expectAa('textPrimary', p.textPrimary, bg);
          expectAa('textSecondary', p.textSecondary, bg);
          expectAa('textHint', p.textHint, bg);
          expectAa('gray400', p.gray400, bg);
          expectAa('gray500', p.gray500, bg);
          expectAa('gray700', p.gray700, bg);
          expectAa('primaryText', p.primaryText, bg);
        }
      });

      test('status text on tinted backgrounds', () {
        for (final bg in [p.surface, p.card]) {
          expectAa('open', p.statusOpenText, _tint(QioColors.statusOpen, bg));
          expectAa(
            'paused',
            p.statusPausedText,
            _tint(QioColors.statusPaused, bg),
          );
          expectAa(
            'closed',
            p.statusClosedText,
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
