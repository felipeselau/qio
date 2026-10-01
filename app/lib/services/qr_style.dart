import 'dart:math' as math;

import 'package:flutter/material.dart';

enum QrColorPreset {
  azul('Azul', Color(0xFF1D4ED8)),
  preto('Preto', Color(0xFF111827)),
  verdeEscuro('Verde escuro', Color(0xFF047857));

  const QrColorPreset(this.label, this.color);

  final String label;
  final Color color;
}

double contrastRatio(Color fg, Color bg) {
  final l1 = fg.computeLuminance();
  final l2 = bg.computeLuminance();
  final lighter = math.max(l1, l2);
  final darker = math.min(l1, l2);
  return (lighter + 0.05) / (darker + 0.05);
}

bool isContrastOk(Color fg, {Color bg = Colors.white}) =>
    contrastRatio(fg, bg) >= 4.5;
