import 'package:flutter/material.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';

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

  Color get _foregroundColor {
    switch (status) {
      case QioBadgeStatus.open:
        return QioColors.statusOpen;
      case QioBadgeStatus.paused:
        return QioColors.statusPaused;
      case QioBadgeStatus.closed:
        return QioColors.statusClosed;
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
        style: QioTextStyles.caption.copyWith(
          color: _foregroundColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
