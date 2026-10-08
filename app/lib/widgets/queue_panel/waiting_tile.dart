import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/queue_entry.dart';
import '../../models/queue_slot.dart';
import '../../theme/qio_colors.dart';
import '../../theme/qio_text_styles.dart';
import '../../widgets/qio_avatar.dart';

class WaitingTile extends StatelessWidget {
  const WaitingTile({super.key, required this.entry, this.trailing});

  final QueueEntry entry;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final waitMin = DateTime.now().difference(entry.joinedAt).inMinutes;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: QioColors.surface,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 1),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              QioAvatar(name: entry.name, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: QioTextStyles.bodyMedium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: QioColors.textPrimary,
                      ),
                    ),
                    if (entry.slotStart != null)
                      Text(
                        l10n.waitTileSlot(
                          formatSlotStart(
                            entry.slotStart!.millisecondsSinceEpoch,
                          ),
                        ),
                        style: QioTextStyles.caption.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: QioColors.primaryText,
                        ),
                      ),
                    Text(
                      l10n.waitTileSubtitle(entry.ticket, waitMin),
                      style: QioTextStyles.caption.copyWith(
                        fontSize: 12,
                        color: QioColors.gray400,
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}
