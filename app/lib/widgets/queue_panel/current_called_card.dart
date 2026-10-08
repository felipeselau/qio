import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/queue_entry.dart';
import '../../theme/qio_colors.dart';
import '../../theme/qio_text_styles.dart';
import '../../widgets/qio_card.dart';
import '../../theme/qio_palette.dart';

class CurrentCalledCard extends StatelessWidget {
  const CurrentCalledCard({
    super.key,
    this.entry,
    required this.queueId,
    this.onRecall,
  });

  final QueueEntry? entry;
  final String queueId;
  final VoidCallback? onRecall;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (entry == null) {
      return QioCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(Icons.person_search, size: 40, color: context.qio.gray300),
              const SizedBox(height: 12),
              Text(l10n.nobodyCalled, style: context.qioText.bodyMedium),
              const SizedBox(height: 4),
              Text(l10n.callNextHint, style: context.qioText.caption),
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
            style: context.qioText.label.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.6),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '#${e.ticket}',
            style: context.qioText.ticket.copyWith(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            e.name,
            style: context.qioText.heading3.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (e.recalls > 0) ...[
            const SizedBox(height: 4),
            Text(
              l10n.calledTimes(e.recalls + 1),
              style: context.qioText.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
          if (onRecall != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRecall,
              icon: const Icon(Icons.campaign_outlined),
              label: Text(l10n.callAgain),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white70),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
