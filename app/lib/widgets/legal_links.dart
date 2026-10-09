import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/legal_links.dart';
import '../theme/qio_palette.dart';
import '../theme/qio_text_styles.dart';

class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key, this.onOpen = openLegalUrl});

  final Future<bool> Function(Uri uri) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = context.qioText.caption.copyWith(
      color: context.qio.textSecondary,
      decoration: TextDecoration.underline,
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        TextButton(
          onPressed: () => onOpen(privacyUrl),
          child: Text(l10n.privacyPolicy, style: style),
        ),
        TextButton(
          onPressed: () => onOpen(termsUrl),
          child: Text(l10n.termsOfUse, style: style),
        ),
      ],
    );
  }
}
