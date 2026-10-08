import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/qio_colors.dart';
import '../../theme/qio_text_styles.dart';
import '../../widgets/qio_card.dart';
import '../../screens/operators_screen.dart';
import '../../theme/qio_palette.dart';

class OperatorsTile extends StatelessWidget {
  const OperatorsTile({super.key, required this.queueId});

  final String queueId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return QioCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => OperatorsScreen(queueId: queueId)),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_outlined, color: QioColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.operatorsAndInvites,
              style: context.qioText.bodyMedium.copyWith(
                color: context.qio.textPrimary,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: context.qio.gray400),
        ],
      ),
    );
  }
}
