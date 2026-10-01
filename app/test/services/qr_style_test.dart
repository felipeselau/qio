import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/qr_style.dart';

void main() {
  test('preto sobre branco tem contraste 21', () {
    expect(contrastRatio(Colors.black, Colors.white), closeTo(21, 0.001));
  });

  test('branco sobre branco tem contraste 1', () {
    expect(contrastRatio(Colors.white, Colors.white), closeTo(1, 0.001));
  });

  test('todos os presets passam no contraste', () {
    for (final p in QrColorPreset.values) {
      expect(isContrastOk(p.color), isTrue, reason: p.label);
    }
  });

  test('amarelo é reprovado', () {
    expect(isContrastOk(Colors.yellow), isFalse);
  });
}
