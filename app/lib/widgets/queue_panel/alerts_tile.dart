import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/alerts_config.dart';
import '../../screens/alerts_settings_screen.dart';
import '../../theme/qio_colors.dart';
import '../../theme/qio_text_styles.dart';
import '../qio_card.dart';

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
            color: QioColors.primaryText,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.alertsTitle,
                  style: QioTextStyles.bodyMedium.copyWith(
                    color: QioColors.textPrimary,
                  ),
                ),
                Text(
                  on ? l10n.alertsActive(c.activeRules) : l10n.alertsOff,
                  style: QioTextStyles.caption,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, size: 20, color: QioColors.gray500),
        ],
      ),
    );
  }
}
