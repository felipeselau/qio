import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

enum QrColorPreset {
  azul(Color(0xFF1D4ED8)),
  preto(Color(0xFF111827)),
  verdeEscuro(Color(0xFF047857));

  const QrColorPreset(this.color);

  final Color color;

  String label(AppLocalizations l10n) => switch (this) {
    QrColorPreset.azul => l10n.qrColorBlue,
    QrColorPreset.preto => l10n.qrColorBlack,
    QrColorPreset.verdeEscuro => l10n.qrColorDarkGreen,
  };
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
