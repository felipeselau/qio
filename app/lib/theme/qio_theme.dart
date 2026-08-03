import 'package:flutter/material.dart';
import 'qio_colors.dart';
import 'qio_text_styles.dart';

class QioTheme {
  QioTheme._();

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: QioColors.background,
      colorScheme: const ColorScheme.light(
        primary: QioColors.primary,
        onPrimary: QioColors.textOnPrimary,
        secondary: QioColors.secondary,
        onSecondary: QioColors.textOnSecondary,
        surface: QioColors.surface,
        onSurface: QioColors.textPrimary,
        error: QioColors.error,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: QioColors.surface,
        foregroundColor: QioColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: QioTextStyles.heading2,
      ),
      cardTheme: CardThemeData(
        color: QioColors.card,
        elevation: 1,
        shadowColor: QioColors.gray900.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: QioColors.gray50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: QioColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: QioColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: QioColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: QioColors.error),
        ),
        labelStyle: QioTextStyles.label,
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: QioColors.textHint,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: QioColors.gray200,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: QioColors.primary,
          foregroundColor: QioColors.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: QioTextStyles.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: QioColors.primary,
          side: const BorderSide(color: QioColors.gray300),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: QioTextStyles.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: QioColors.primary,
          textStyle: QioTextStyles.bodyMedium,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: QioColors.primary,
        foregroundColor: QioColors.textOnPrimary,
        elevation: 2,
        shape: CircleBorder(),
      ),
    );
  }
}
