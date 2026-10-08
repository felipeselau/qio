import 'package:flutter/material.dart';
import 'qio_palette.dart';

class QioColors {
  QioColors._();

  static bool _dark = false;

  static QioPalette get _p => _dark ? QioPalette.dark : QioPalette.light;

  static bool get isDark => _dark;

  static void apply(Brightness brightness) {
    _dark = brightness == Brightness.dark;
  }

  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryDark = Color(0xFF059669);
  static const Color secondaryLight = Color(0xFF34D399);

  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get card => _p.card;

  static Color get gray50 => _p.gray50;
  static Color get gray100 => _p.gray100;
  static Color get gray200 => _p.gray200;
  static Color get gray300 => _p.gray300;
  static Color get gray400 => _p.gray400;
  static Color get gray500 => _p.gray500;
  static Color get gray600 => _p.gray600;
  static Color get gray700 => _p.gray700;
  static Color get gray800 => _p.gray800;
  static Color get gray900 => _p.gray900;

  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF3B82F6);

  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary;
  static Color get textHint => _p.textHint;
  static const Color textOnPrimary = Colors.white;
  static const Color textOnSecondary = Colors.white;

  static const Color statusOpen = Color(0xFF10B981);
  static const Color statusPaused = Color(0xFFF59E0B);
  static const Color statusClosed = Color(0xFFEF4444);

  static Color get primaryText => _p.primaryText;
  static Color get statusOpenText => _p.statusOpenText;
  static Color get statusPausedText => _p.statusPausedText;
  static Color get statusClosedText => _p.statusClosedText;
  static const Color successStrong = Color(0xFF047857);
  static const Color dangerStrong = Color(0xFFDC2626);
}
