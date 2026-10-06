import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/queue_entry.dart';
import '../../theme/qio_colors.dart';
import '../../theme/qio_text_styles.dart';
import '../../widgets/qio_card.dart';

class CurrentCalledCard extends StatelessWidget {
  const CurrentCalledCard({super.key, this.entry, required this.queueId});

  final QueueEntry? entry;
  final String queueId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (entry == null) {
      return QioCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(Icons.person_search, size: 40, color: QioColors.gray300),
              const SizedBox(height: 12),
              Text(l10n.nobodyCalled, style: QioTextStyles.bodyMedium),
              const SizedBox(height: 4),
              Text(l10n.callNextHint, style: QioTextStyles.caption),
            ],
          ),
        ),
      );
    }
    final e = entry!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: QioColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: QioColors.primary.withValues(alpha: 0.25),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            l10n.callingNow,
            style: QioTextStyles.label.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.6),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '#${e.ticket}',
            style: QioTextStyles.ticket.copyWith(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            e.name,
            style: QioTextStyles.heading3.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
