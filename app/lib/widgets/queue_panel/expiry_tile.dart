import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/expiry_config.dart';
import '../../services/queue_service.dart';
import '../../theme/qio_colors.dart';
import '../../theme/qio_palette.dart';
import '../../theme/qio_text_styles.dart';
import '../qio_card.dart';

class ExpiryTile extends StatefulWidget {
  const ExpiryTile({
    super.key,
    required this.queueId,
    required this.config,
    this.queues,
  });

  final String queueId;
  final ExpiryConfig? config;
  final QueueService? queues;

  @override
  State<ExpiryTile> createState() => _ExpiryTileState();
}

class _ExpiryTileState extends State<ExpiryTile> {
  bool _busy = false;

  ExpiryConfig get _current => widget.config ?? const ExpiryConfig();

  Future<void> _save(ExpiryConfig next) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await (widget.queues ?? QueueService.instance).updateExpiry(
        widget.queueId,
        next,
      );
    } on Exception {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.genericActionError),
          backgroundColor: QioColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = _current;
    final hours = ExpiryConfig.hourOptions.contains(config.hours)
        ? config.hours
        : ExpiryConfig.defaultHours;
    return QioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Row(
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
                onChanged: _busy
                    ? null
                    : (v) => _save(config.copyWith(enabled: v)),
              ),
            ],
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
                    for (final h in ExpiryConfig.hourOptions)
                      DropdownMenuItem(value: h, child: Text('$h h')),
                  ],
                  onChanged: _busy
                      ? null
                      : (v) {
                          if (v != null) _save(config.copyWith(hours: v));
                        },
                ),
              ],
            ),
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
                  onChanged: _busy
                      ? null
                      : (v) => _save(config.copyWith(clearOnClose: v)),
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
                  onChanged: _busy
                      ? null
                      : (v) => _save(config.copyWith(resetTicketDaily: v)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
