import 'package:flutter/material.dart';
import 'qio_colors.dart';

class QioTextStyles {
  QioTextStyles._();

  static const String _fontFamily = 'Inter';

  static TextStyle get display => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: QioColors.textPrimary,
    height: 1.2,
  );

  static TextStyle get heading1 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: QioColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get heading2 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: QioColors.textPrimary,
    height: 1.3,
  );

  static TextStyle get heading3 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: QioColors.textPrimary,
    height: 1.4,
  );

  static TextStyle get body => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: QioColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: QioColors.textPrimary,
    height: 1.5,
  );

  static TextStyle get caption => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: QioColors.textSecondary,
    height: 1.4,
  );

  static TextStyle get label => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: QioColors.textSecondary,
    height: 1.4,
  );

  static TextStyle get button => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static TextStyle get ticket => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: QioColors.textPrimary,
    height: 1.1,
  );
}
