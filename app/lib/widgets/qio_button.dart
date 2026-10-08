import 'package:flutter/material.dart';
import '../services/haptics.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../theme/qio_palette.dart';

enum QioButtonVariant {
  primary,
  secondary,
  ghost,
  danger,
  successSoft,
  dangerSoft,
}

class QioButton extends StatelessWidget {
  const QioButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = QioButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.padding,
    this.fontSize = 16,
  });

  final String label;
  final VoidCallback? onPressed;
  final QioButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null && !isLoading;

    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;

    switch (variant) {
      case QioButtonVariant.primary:
        backgroundColor = isDisabled ? context.qio.gray300 : QioColors.primary;
        foregroundColor = QioColors.textOnPrimary;
        borderColor = Colors.transparent;
      case QioButtonVariant.secondary:
        backgroundColor = isDisabled
            ? context.qio.gray100
            : context.qio.surface;
        foregroundColor = isDisabled
            ? context.qio.gray400
            : context.qio.primaryText;
        borderColor = isDisabled ? context.qio.gray200 : context.qio.gray300;
      case QioButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = isDisabled
            ? context.qio.gray400
            : context.qio.primaryText;
        borderColor = Colors.transparent;
      case QioButtonVariant.danger:
        backgroundColor = isDisabled
            ? context.qio.gray300
            : QioColors.dangerStrong;
        foregroundColor = Colors.white;
        borderColor = Colors.transparent;
      case QioButtonVariant.successSoft:
        backgroundColor = QioColors.success.withValues(alpha: 0.12);
        foregroundColor = isDisabled
            ? context.qio.gray400
            : context.qio.statusOpenText;
        borderColor = Colors.transparent;
      case QioButtonVariant.dangerSoft:
        backgroundColor = QioColors.error.withValues(alpha: 0.12);
        foregroundColor = isDisabled
            ? context.qio.gray400
            : context.qio.statusClosedText;
        borderColor = Colors.transparent;
    }

    final content = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: context.qioText.button.copyWith(
                      color: foregroundColor,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      enabled: !isDisabled && !isLoading,
      label: label,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (isLoading || onPressed == null)
                ? null
                : () {
                    Haptics.instance.selection();
                    onPressed!();
                  },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding:
                  padding ??
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
  }
}
