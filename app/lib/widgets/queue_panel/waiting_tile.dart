import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/queue_entry.dart';
import '../../models/queue_slot.dart';
import '../../theme/qio_text_styles.dart';
import '../../services/phone_call.dart';
import '../../widgets/qio_avatar.dart';
import 'phone_call_button.dart';
import '../../theme/qio_palette.dart';

class WaitingTile extends StatelessWidget {
  const WaitingTile({
    super.key,
    required this.entry,
    this.trailing,
    this.launcher,
  });

  final QueueEntry entry;
  final Widget? trailing;
  final UrlLauncher? launcher;

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
            color: context.qio.surface,
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.name,
                            overflow: TextOverflow.ellipsis,
                            style: context.qioText.bodyMedium.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: context.qio.textPrimary,
                            ),
                          ),
                        ),
                        if (entry.manual) ...[
                          const SizedBox(width: 8),
                          _CounterBadge(label: l10n.manualBadge),
                        ],
                      ],
                    ),
                    if (entry.slotStart != null)
                      Text(
                        l10n.waitTileSlot(
                          formatSlotStart(
                            entry.slotStart!.millisecondsSinceEpoch,
                          ),
                        ),
                        style: context.qioText.caption.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.qio.primaryText,
                        ),
                      ),
                    if (phoneToTelUri(entry.phone) != null)
                      Text(
                        entry.phone!.trim(),
                        style: context.qioText.caption.copyWith(
                          fontSize: 12,
                          color: context.qio.gray700,
                        ),
                      ),
                    Text(
                      l10n.waitTileSubtitle(entry.ticket, waitMin),
                      style: context.qioText.caption.copyWith(
                        fontSize: 12,
                        color: context.qio.gray400,
                      ),
                    ),
                  ],
                ),
              ),
              PhoneCallButton(
                phone: entry.phone,
                name: entry.name,
                launcher: launcher,
              ),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _CounterBadge extends StatelessWidget {
  const _CounterBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.qio.primaryText.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: context.qioText.caption.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: context.qio.primaryText,
        ),
      ),
    );
  }
}
