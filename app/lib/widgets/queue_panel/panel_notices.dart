import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/queue_entry.dart';
import '../../services/onboarding_service.dart';
import '../../theme/qio_colors.dart';
import '../../theme/qio_palette.dart';
import '../../theme/qio_text_styles.dart';
import '../onboarding_tour.dart';

void showPanelTour(BuildContext context, GlobalKey qrKey, GlobalKey callKey) {
  final l10n = AppLocalizations.of(context);
  showOnboardingTour(context, OnboardingTour.panel, [
    OnboardingStep(
      key: qrKey,
      title: l10n.tourPanelQrTitle,
      body: l10n.tourPanelQrBody,
    ),
    OnboardingStep(
      key: callKey,
      title: l10n.tourPanelCallTitle,
      body: l10n.tourPanelCallBody,
      above: true,
    ),
  ]);
}

void announceNewEntries(
  BuildContext context,
  List<QueueEntry> entries,
  Set<String> added,
) {
  HapticFeedback.mediumImpact();
  SystemSound.play(SystemSoundType.alert);
  final l10n = AppLocalizations.of(context);
  final message = added.length == 1
      ? l10n.newPersonInQueue(
          entries.firstWhere((e) => e.id == added.first).name,
        )
      : l10n.newPeopleInQueue(added.length);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
}

void showSyncError(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(AppLocalizations.of(context).syncError),
      backgroundColor: QioColors.error,
    ),
  );
}

Future<void> showAccessEndedDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text(l10n.accessEndedTitle),
      content: Text(l10n.accessEndedBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.ok),
        ),
      ],
    ),
  );
}

void showNobodyInQueue(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(AppLocalizations.of(context).nobodyInQueue),
      backgroundColor: QioColors.warning,
    ),
  );
}

class QueueBackButton extends StatelessWidget {
  const QueueBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Text(
        '←',
        style: context.qioText.heading3.copyWith(
          color: context.qio.primaryText,
        ),
      ),
    );
  }
}
