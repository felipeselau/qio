import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../l10n/app_localizations.dart';
import '../../services/brand_palette.dart';
import '../../services/queue_service.dart';
import '../../theme/qio_colors.dart';
import '../../theme/qio_text_styles.dart';
import '../qio_card.dart';

class QueueBrandTile extends StatelessWidget {
  const QueueBrandTile({
    super.key,
    required this.queueId,
    required this.queueName,
    required this.brandColor,
    required this.logoUrl,
  });

  final String queueId;
  final String queueName;
  final String? brandColor;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hex = isValidBrandHex(brandColor) ? brandColor! : null;
    final accent = hex == null
        ? QioColors.primaryText
        : BrandColor(hex.toUpperCase(), '').color;
    return QioCard(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _BrandDialog(
          queueId: queueId,
          initialColor: hex,
          initialLogo: logoUrl,
        ),
      ),
      child: Row(
        children: [
          _LogoBadge(url: logoUrl, color: accent, name: queueName, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.brandTitle,
                  style: QioTextStyles.bodyMedium.copyWith(
                    color: QioColors.textPrimary,
                  ),
                ),
                Text(l10n.brandSubtitle, style: QioTextStyles.caption),
              ],
            ),
          ),
          Icon(Icons.edit_outlined, size: 18, color: QioColors.gray500),
        ],
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge({
    required this.url,
    required this.color,
    required this.name,
    required this.size,
  });

  final String? url;
  final Color color;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? 'Q' : name.trim()[0].toUpperCase();
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: Text(
        initial,
        style: QioTextStyles.heading3.copyWith(
          color: Colors.white,
          fontSize: size * 0.45,
        ),
      ),
    );
    if (url == null) return fallback;
    return ClipOval(
      child: Image.network(
        url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}

class _BrandDialog extends StatefulWidget {
  const _BrandDialog({
    required this.queueId,
    required this.initialColor,
    required this.initialLogo,
  });

  final String queueId;
  final String? initialColor;
  final String? initialLogo;

  @override
  State<_BrandDialog> createState() => _BrandDialogState();
}

class _BrandDialogState extends State<_BrandDialog> {
  late String? _color = widget.initialColor?.toUpperCase();
  late String? _logo = widget.initialLogo;
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Exception {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).brandError),
          backgroundColor: QioColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setColor(String? hex) => _run(() async {
    await QueueService.instance.updateBrandColor(widget.queueId, hex);
    if (mounted) setState(() => _color = hex);
  });

  Future<void> _pickLogo() => _run(() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final url = await QueueService.instance.uploadLogo(widget.queueId, bytes);
    if (mounted) setState(() => _logo = url);
  });

  Future<void> _removeLogo() => _run(() async {
    await QueueService.instance.removeLogo(widget.queueId);
    if (mounted) setState(() => _logo = null);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final accent = _color == null
        ? QioColors.primaryText
        : BrandColor(_color!, '').color;
    return AlertDialog(
      title: Text(l10n.brandTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.brandColorLabel, style: QioTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final c in brandPalette)
                  Semantics(
                    button: true,
                    selected: _color == c.hex,
                    label: c.hex,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _busy ? null : () => _setColor(c.hex),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: c.color,
                          shape: BoxShape.circle,
                        ),
                        child: _color == c.hex
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(l10n.brandLogoLabel, style: QioTextStyles.label),
            const SizedBox(height: 8),
            Row(
              children: [
                _LogoBadge(url: _logo, color: accent, name: 'Q', size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: _busy ? null : _pickLogo,
                        child: Text(l10n.brandChooseImage),
                      ),
                      if (_logo != null)
                        TextButton(
                          onPressed: _busy ? null : _removeLogo,
                          child: Text(l10n.remove),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (_busy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.ok),
        ),
      ],
    );
  }
}
