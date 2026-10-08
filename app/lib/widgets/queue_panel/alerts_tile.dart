import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/alerts_config.dart';
import '../../screens/alerts_settings_screen.dart';
import '../../theme/qio_text_styles.dart';
import '../qio_card.dart';
import '../../theme/qio_palette.dart';

class AlertsTile extends StatelessWidget {
  const AlertsTile({super.key, required this.queueId, required this.config});

  final String queueId;
  final AlertsConfig? config;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = config;
    final on = c != null && c.enabled && c.activeRules > 0;
    return QioCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              AlertsSettingsScreen(queueId: queueId, initial: config),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.notifications_active_outlined,
            color: context.qio.primaryText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.alertsTitle,
                  style: context.qioText.bodyMedium.copyWith(
                    color: context.qio.textPrimary,
                  ),
                ),
                Text(
                  on ? l10n.alertsActive(c.activeRules) : l10n.alertsOff,
                  style: context.qioText.caption,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: context.qio.gray500),
        ],
      ),
    );
  }
}
