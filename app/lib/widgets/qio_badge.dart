import 'package:flutter/material.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../theme/qio_palette.dart';

enum QioBadgeStatus { open, paused, closed }

class QioBadge extends StatelessWidget {
  const QioBadge({super.key, required this.label, required this.status});

  final String label;
  final QioBadgeStatus status;

  Color get _backgroundColor {
    switch (status) {
      case QioBadgeStatus.open:
        return QioColors.statusOpen.withValues(alpha: 0.12);
      case QioBadgeStatus.paused:
        return QioColors.statusPaused.withValues(alpha: 0.12);
      case QioBadgeStatus.closed:
        return QioColors.statusClosed.withValues(alpha: 0.12);
    }
  }

  Color _foregroundColor(BuildContext context) {
    switch (status) {
      case QioBadgeStatus.open:
        return context.qio.statusOpenText;
      case QioBadgeStatus.paused:
        return context.qio.statusPausedText;
      case QioBadgeStatus.closed:
        return context.qio.statusClosedText;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: context.qioText.caption.copyWith(
          color: _foregroundColor(context),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
