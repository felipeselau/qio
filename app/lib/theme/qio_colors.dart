import 'package:flutter/material.dart';

class QioColors {
  QioColors._();

  static bool _dark = false;

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

  static Color get background => _dark ? Color(0xFF0B1220) : Color(0xFFF9FAFB);
  static Color get surface => _dark ? Color(0xFF111827) : Colors.white;
  static Color get card => _dark ? Color(0xFF1F2937) : Colors.white;

  static Color get gray50 => _dark ? Color(0xFF111827) : Color(0xFFF9FAFB);
  static Color get gray100 => _dark ? Color(0xFF0B1220) : Color(0xFFF3F4F6);
  static Color get gray200 => _dark ? Color(0xFF374151) : Color(0xFFE5E7EB);
  static Color get gray300 => _dark ? Color(0xFF4B5563) : Color(0xFFD1D5DB);
  static Color get gray400 => _dark ? Color(0xFF6B7280) : Color(0xFF9CA3AF);
  static Color get gray500 => _dark ? Color(0xFF9CA3AF) : Color(0xFF6B7280);
  static Color get gray600 => _dark ? Color(0xFFD1D5DB) : Color(0xFF4B5563);
  static Color get gray700 => _dark ? Color(0xFFD1D5DB) : Color(0xFF374151);
  static Color get gray800 => _dark ? Color(0xFFE5E7EB) : Color(0xFF1F2937);
  static Color get gray900 => _dark ? Color(0xFFF3F4F6) : Color(0xFF111827);

  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF3B82F6);

  static Color get textPrimary => _dark ? Color(0xFFF9FAFB) : Color(0xFF111827);
  static Color get textSecondary =>
      _dark ? Color(0xFF9CA3AF) : Color(0xFF6B7280);
  static Color get textHint => _dark ? Color(0xFF6B7280) : Color(0xFF9CA3AF);
  static const Color textOnPrimary = Colors.white;
  static const Color textOnSecondary = Colors.white;

  static const Color statusOpen = Color(0xFF10B981);
  static const Color statusPaused = Color(0xFFF59E0B);
  static const Color statusClosed = Color(0xFFEF4444);
}
