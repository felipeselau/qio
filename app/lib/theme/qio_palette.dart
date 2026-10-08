import 'package:flutter/material.dart';

@immutable
class QioPalette extends ThemeExtension<QioPalette> {
  const QioPalette({
    required this.background,
    required this.surface,
    required this.card,
    required this.gray50,
    required this.gray100,
    required this.gray200,
    required this.gray300,
    required this.gray400,
    required this.gray500,
    required this.gray600,
    required this.gray700,
    required this.gray800,
    required this.gray900,
    required this.textPrimary,
    required this.textSecondary,
    required this.textHint,
    required this.primaryText,
    required this.statusOpenText,
    required this.statusPausedText,
    required this.statusClosedText,
  });

  final Color background;
  final Color surface;
  final Color card;
  final Color gray50;
  final Color gray100;
  final Color gray200;
  final Color gray300;
  final Color gray400;
  final Color gray500;
  final Color gray600;
  final Color gray700;
  final Color gray800;
  final Color gray900;
  final Color textPrimary;
  final Color textSecondary;
  final Color textHint;
  final Color primaryText;
  final Color statusOpenText;
  final Color statusPausedText;
  final Color statusClosedText;

  static const QioPalette light = QioPalette(
    background: Color(0xFFF9FAFB),
    surface: Colors.white,
    card: Colors.white,
    gray50: Color(0xFFF9FAFB),
    gray100: Color(0xFFF3F4F6),
    gray200: Color(0xFFE5E7EB),
    gray300: Color(0xFFD1D5DB),
    gray400: Color(0xFF626B7A),
    gray500: Color(0xFF5B6472),
    gray600: Color(0xFF4B5563),
    gray700: Color(0xFF374151),
    gray800: Color(0xFF1F2937),
    gray900: Color(0xFF111827),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF5B6472),
    textHint: Color(0xFF626B7A),
    primaryText: Color(0xFF2563EB),
    statusOpenText: Color(0xFF047857),
    statusPausedText: Color(0xFF92400E),
    statusClosedText: Color(0xFFB91C1C),
  );

  static const QioPalette dark = QioPalette(
    background: Color(0xFF0B1220),
    surface: Color(0xFF111827),
    card: Color(0xFF1F2937),
    gray50: Color(0xFF111827),
    gray100: Color(0xFF0B1220),
    gray200: Color(0xFF374151),
    gray300: Color(0xFF4B5563),
    gray400: Color(0xFF9AA3B2),
    gray500: Color(0xFFA3ABB8),
    gray600: Color(0xFFD1D5DB),
    gray700: Color(0xFFD1D5DB),
    gray800: Color(0xFFE5E7EB),
    gray900: Color(0xFFF3F4F6),
    textPrimary: Color(0xFFF9FAFB),
    textSecondary: Color(0xFFA3ABB8),
    textHint: Color(0xFF9AA3B2),
    primaryText: Color(0xFF60A5FA),
    statusOpenText: Color(0xFF34D399),
    statusPausedText: Color(0xFFFBBF24),
    statusClosedText: Color(0xFFFCA5A5),
  );

  static QioPalette forBrightness(Brightness b) =>
      b == Brightness.dark ? dark : light;

  @override
  QioPalette copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? gray50,
    Color? gray100,
    Color? gray200,
    Color? gray300,
    Color? gray400,
    Color? gray500,
    Color? gray600,
    Color? gray700,
    Color? gray800,
    Color? gray900,
    Color? textPrimary,
    Color? textSecondary,
    Color? textHint,
    Color? primaryText,
    Color? statusOpenText,
    Color? statusPausedText,
    Color? statusClosedText,
  }) {
    return QioPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      card: card ?? this.card,
      gray50: gray50 ?? this.gray50,
      gray100: gray100 ?? this.gray100,
      gray200: gray200 ?? this.gray200,
      gray300: gray300 ?? this.gray300,
      gray400: gray400 ?? this.gray400,
      gray500: gray500 ?? this.gray500,
      gray600: gray600 ?? this.gray600,
      gray700: gray700 ?? this.gray700,
      gray800: gray800 ?? this.gray800,
      gray900: gray900 ?? this.gray900,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textHint: textHint ?? this.textHint,
      primaryText: primaryText ?? this.primaryText,
      statusOpenText: statusOpenText ?? this.statusOpenText,
      statusPausedText: statusPausedText ?? this.statusPausedText,
      statusClosedText: statusClosedText ?? this.statusClosedText,
    );
  }

  @override
  QioPalette lerp(ThemeExtension<QioPalette>? other, double t) {
    if (other is! QioPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return QioPalette(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      card: l(card, other.card),
      gray50: l(gray50, other.gray50),
      gray100: l(gray100, other.gray100),
      gray200: l(gray200, other.gray200),
      gray300: l(gray300, other.gray300),
      gray400: l(gray400, other.gray400),
      gray500: l(gray500, other.gray500),
      gray600: l(gray600, other.gray600),
      gray700: l(gray700, other.gray700),
      gray800: l(gray800, other.gray800),
      gray900: l(gray900, other.gray900),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textHint: l(textHint, other.textHint),
      primaryText: l(primaryText, other.primaryText),
      statusOpenText: l(statusOpenText, other.statusOpenText),
      statusPausedText: l(statusPausedText, other.statusPausedText),
      statusClosedText: l(statusClosedText, other.statusClosedText),
    );
  }
}

extension QioPaletteContext on BuildContext {
  QioPalette get qio =>
      Theme.of(this).extension<QioPalette>() ??
      QioPalette.forBrightness(Theme.of(this).brightness);
}
