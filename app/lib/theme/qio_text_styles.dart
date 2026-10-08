import 'package:flutter/material.dart';
import 'qio_palette.dart';

class QioTextStyles {
  const QioTextStyles(this.palette);

  final QioPalette palette;

  static const String _fontFamily = 'Inter';

  TextStyle get display => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: palette.textPrimary,
    height: 1.2,
  );

  TextStyle get heading1 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: palette.textPrimary,
    height: 1.3,
  );

  TextStyle get heading2 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: palette.textPrimary,
    height: 1.3,
  );

  TextStyle get heading3 => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: palette.textPrimary,
    height: 1.4,
  );

  TextStyle get body => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: palette.textPrimary,
    height: 1.5,
  );

  TextStyle get bodyMedium => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: palette.textPrimary,
    height: 1.5,
  );

  TextStyle get caption => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: palette.textSecondary,
    height: 1.4,
  );

  TextStyle get label => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: palette.textSecondary,
    height: 1.4,
  );

  TextStyle get button => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  TextStyle get ticket => TextStyle(
    fontFamily: _fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w800,
    color: palette.textPrimary,
    height: 1.1,
  );
}

extension QioTextStylesContext on BuildContext {
  QioTextStyles get qioText => QioTextStyles(qio);
}
