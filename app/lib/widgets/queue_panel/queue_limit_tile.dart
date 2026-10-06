import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/queue_service.dart';
import '../../theme/qio_colors.dart';
import '../../theme/qio_text_styles.dart';
import '../qio_card.dart';
import '../qio_input.dart';

String? validateMaxWaiting(String? value, AppLocalizations l10n) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final n = int.tryParse(text);
  if (n == null || n < 1 || n > 1000) return l10n.maxWaitingInvalid;
  return null;
}

class QueueLimitTile extends StatelessWidget {
  const QueueLimitTile({
    super.key,
    required this.queueId,
    required this.maxWaiting,
  });

  final String queueId;
  final int maxWaiting;

  Future<void> _edit(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: maxWaiting > 0 ? '$maxWaiting' : '',
    );
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.queueLimitTitle),
        content: Form(
          key: formKey,
          child: QioInput(
            label: l10n.maxWaitingLabel,
            hint: l10n.maxWaitingHint,
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            validator: (v) => validateMaxWaiting(v, l10n),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(ctx).pop(int.tryParse(controller.text.trim()) ?? 0);
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (saved == null || !context.mounted) return;
    try {
      await QueueService.instance.updateMaxWaiting(queueId, saved);
    } on Exception {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.genericActionError),
          backgroundColor: QioColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return QioCard(
      onTap: () => _edit(context),
      child: Row(
        children: [
          Icon(Icons.people_alt_outlined, color: QioColors.primaryText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.queueLimitTitle,
                  style: QioTextStyles.bodyMedium.copyWith(
                    color: QioColors.textPrimary,
                  ),
                ),
                Text(
                  maxWaiting > 0
                      ? l10n.queueLimitValue(maxWaiting)
                      : l10n.queueLimitNone,
                  style: QioTextStyles.caption,
                ),
              ],
            ),
          ),
          Icon(Icons.edit_outlined, size: 18, color: QioColors.gray500),
        ],
      ),
    );
  }
}
