import 'dart:async';
import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/qio_colors.dart';
import '../../theme/qio_text_styles.dart';
import '../../widgets/qio_button.dart';
import '../../theme/qio_palette.dart';

Future<bool> confirmDeleteQueue(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: QioColors.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_outline,
              color: QioColors.error,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.deleteQueueTitle,
            style: context.qioText.heading2.copyWith(
              fontWeight: FontWeight.w700,
              color: context.qio.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.deleteQueueBody,
            style: context.qioText.body.copyWith(
              fontSize: 14,
              color: context.qio.gray500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: QioButton(
                  label: l10n.cancel,
                  variant: QioButtonVariant.secondary,
                  isFullWidth: true,
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QioButton(
                  label: l10n.delete,
                  variant: QioButtonVariant.danger,
                  isFullWidth: true,
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return confirmed == true;
}
