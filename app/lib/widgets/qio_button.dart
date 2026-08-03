import 'package:flutter/material.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';

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
  });

  final String label;
  final VoidCallback? onPressed;
  final QioButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null && !isLoading;

    Color backgroundColor;
    Color foregroundColor;
    Color borderColor;

    switch (variant) {
      case QioButtonVariant.primary:
        backgroundColor = isDisabled ? QioColors.gray300 : QioColors.primary;
        foregroundColor = QioColors.textOnPrimary;
        borderColor = Colors.transparent;
      case QioButtonVariant.secondary:
        backgroundColor = isDisabled ? QioColors.gray100 : QioColors.surface;
        foregroundColor = isDisabled ? QioColors.gray400 : QioColors.primary;
        borderColor = isDisabled ? QioColors.gray200 : QioColors.gray300;
      case QioButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = isDisabled ? QioColors.gray400 : QioColors.primary;
        borderColor = Colors.transparent;
      case QioButtonVariant.danger:
        backgroundColor = isDisabled ? QioColors.gray300 : QioColors.error;
        foregroundColor = Colors.white;
        borderColor = Colors.transparent;
      case QioButtonVariant.successSoft:
        backgroundColor = QioColors.success.withValues(alpha: 0.12);
        foregroundColor = isDisabled ? QioColors.gray400 : QioColors.success;
        borderColor = Colors.transparent;
      case QioButtonVariant.dangerSoft:
        backgroundColor = QioColors.error.withValues(alpha: 0.12);
        foregroundColor = isDisabled ? QioColors.gray400 : QioColors.error;
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
              Text(
                label,
                style: QioTextStyles.button.copyWith(color: foregroundColor),
              ),
            ],
          );

    return Container(
      width: isFullWidth ? double.infinity : null,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding:
                padding ??
                const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
