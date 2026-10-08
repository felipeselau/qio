import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'qio_colors.dart';
import 'qio_palette.dart';
import 'qio_text_styles.dart';

class QioTheme {
  QioTheme._();

  static final ThemeData light = _build(Brightness.light);

  static final ThemeData dark = _build(Brightness.dark);

  static ThemeData forBrightness(Brightness b) =>
      b == Brightness.dark ? dark : light;

  static ThemeData _build(Brightness brightness) {
    final p = QioPalette.forBrightness(brightness);
    final t = QioTextStyles(p);
    final base = ThemeData(brightness: brightness, useMaterial3: true);

    return base.copyWith(
      extensions: <ThemeExtension<dynamic>>[p],
      scaffoldBackgroundColor: p.background,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: QioColors.primary,
        onPrimary: QioColors.textOnPrimary,
        secondary: QioColors.secondary,
        onSecondary: QioColors.textOnSecondary,
        surface: p.surface,
        onSurface: p.textPrimary,
        error: QioColors.error,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: t.heading2,
      ),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 1,
        shadowColor: p.gray900.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.gray50,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: p.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: p.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: QioColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: QioColors.error),
        ),
        labelStyle: t.label,
        hintStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: p.textHint,
        ),
      ),
      dividerTheme: DividerThemeData(color: p.gray200, thickness: 1, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: QioColors.primary,
          foregroundColor: QioColors.textOnPrimary,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: t.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primaryText,
          side: BorderSide(color: p.gray300),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: t.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primaryText,
          textStyle: t.bodyMedium,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: QioColors.primary,
        foregroundColor: QioColors.textOnPrimary,
        elevation: 2,
        shape: CircleBorder(),
      ),
    );
  }
}
