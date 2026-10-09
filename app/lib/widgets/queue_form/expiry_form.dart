import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/expiry_config.dart';
import '../../theme/qio_palette.dart';
import '../../theme/qio_text_styles.dart';

class ExpiryForm extends StatelessWidget {
  const ExpiryForm({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.showExtras = true,
  });

  final ExpiryConfig value;
  final ValueChanged<ExpiryConfig> onChanged;
  final bool enabled;
  final bool showExtras;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = value;
    final hours = config.hours;
    final options = {...ExpiryConfig.hourOptions, hours}.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        MergeSemantics(
          child: Row(
            children: [
              Icon(Icons.timer_off_outlined, color: context.qio.primaryText),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.expiryTitle,
                      style: context.qioText.bodyMedium.copyWith(
                        color: context.qio.textPrimary,
                      ),
                    ),
                    Text(l10n.expiryHint, style: context.qioText.caption),
                  ],
                ),
              ),
              Switch(
                key: const ValueKey('expiry-enabled'),
                value: config.enabled,
                onChanged: enabled
                    ? (v) => onChanged(config.copyWith(enabled: v))
                    : null,
              ),
            ],
          ),
        ),
        if (config.enabled) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.expiryAfterHours(hours),
                  style: context.qioText.bodyMedium.copyWith(
                    color: context.qio.textPrimary,
                  ),
                ),
              ),
              DropdownButton<int>(
                key: const ValueKey('expiry-hours'),
                value: hours,
                items: [
                  for (final h in options)
                    DropdownMenuItem(value: h, child: Text('$h h')),
                ],
                onChanged: enabled
                    ? (v) {
                        if (v != null) onChanged(config.copyWith(hours: v));
                      }
                    : null,
              ),
            ],
          ),
          if (showExtras) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.expiryClearOnClose,
                    style: context.qioText.bodyMedium.copyWith(
                      color: context.qio.textPrimary,
                    ),
                  ),
                ),
                Switch(
                  key: const ValueKey('expiry-clear'),
                  value: config.clearOnClose,
                  onChanged: enabled
                      ? (v) => onChanged(config.copyWith(clearOnClose: v))
                      : null,
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.expiryResetTicketDaily,
                        style: context.qioText.bodyMedium.copyWith(
                          color: context.qio.textPrimary,
                        ),
                      ),
                      Text(
                        l10n.expiryResetTicketDailyHint,
                        style: context.qioText.caption,
                      ),
                    ],
                  ),
                ),
                Switch(
                  key: const ValueKey('expiry-reset'),
                  value: config.resetTicketDaily,
                  onChanged: enabled
                      ? (v) => onChanged(config.copyWith(resetTicketDaily: v))
                      : null,
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}
