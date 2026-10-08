import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/qio_colors.dart';
import '../../theme/qio_text_styles.dart';
import '../../widgets/qio_button.dart';
import '../../widgets/qio_card.dart';
import '../../screens/qr_poster_screen.dart';
import '../../theme/qio_palette.dart';

class QueueQrCard extends StatelessWidget {
  const QueueQrCard({
    super.key,
    required this.queueName,
    required this.joinUrl,
  });

  final String queueName;
  final String joinUrl;

  Future<void> _copyLink(BuildContext context, String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).linkCopied),
        backgroundColor: QioColors.successStrong,
      ),
    );
  }

  Future<void> _share(BuildContext context, String url) async {
    try {
      await SharePlus.instance.share(ShareParams(text: url));
    } on Exception {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).genericActionError),
          backgroundColor: QioColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return QioCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.qio.gray200),
            ),
            child: Semantics(
              image: true,
              label: l10n.qrSemantics,
              child: QrImageView(
                data: joinUrl,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.scanToJoin,
            style: context.qioText.body.copyWith(
              fontSize: 14,
              color: context.qio.gray700,
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            button: true,
            label: l10n.copyLinkSemantics,
            child: GestureDetector(
              onTap: () => _copyLink(context, joinUrl),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: context.qio.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        joinUrl.replaceFirst('https://', ''),
                        style: context.qioText.caption.copyWith(
                          fontSize: 13,
                          color: context.qio.gray700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.copy, size: 16, color: QioColors.primary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: QioButton(
                  label: l10n.copyLink,
                  icon: Icons.copy,
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  isFullWidth: true,
                  onPressed: () => _copyLink(context, joinUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QioButton(
                  label: l10n.share,
                  variant: QioButtonVariant.secondary,
                  icon: Icons.share_outlined,
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  isFullWidth: true,
                  onPressed: () => _share(context, joinUrl),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          QioButton(
            label: l10n.printablePoster,
            variant: QioButtonVariant.ghost,
            icon: Icons.print,
            fontSize: 14,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            isFullWidth: true,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    QrPosterScreen(queueName: queueName, joinUrl: joinUrl),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
