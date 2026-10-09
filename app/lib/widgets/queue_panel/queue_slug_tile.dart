import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/join_url.dart';
import '../../services/queue_service.dart';
import '../../services/slug.dart';
import '../../theme/qio_colors.dart';
import '../../theme/qio_palette.dart';
import '../../theme/qio_text_styles.dart';
import '../qio_card.dart';
import '../qio_input.dart';

String? validateSlugInput(String? value, AppLocalizations l10n) {
  final text = normalizeSlug(value ?? '');
  if (text.isEmpty) return null;
  return switch (slugError(text)) {
    SlugError.format => l10n.slugInvalid,
    SlugError.reserved => l10n.slugReservedError,
    null => null,
  };
}

class QueueSlugTile extends StatelessWidget {
  const QueueSlugTile({
    super.key,
    required this.queueId,
    required this.slug,
    this.queues,
  });

  final String queueId;
  final String? slug;
  final QueueService? queues;

  Future<void> _edit(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final service = queues ?? QueueService.instance;
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showDialog<_SlugResult>(
      context: context,
      builder: (_) =>
          _SlugDialog(queueId: queueId, currentSlug: slug, service: service),
    );
    if (saved == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(saved.removed ? l10n.slugRemoved : l10n.slugSaved),
        backgroundColor: QioColors.successStrong,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = slug;
    return QioCard(
      onTap: () => _edit(context),
      child: Row(
        children: [
          Icon(Icons.link, color: context.qio.primaryText),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.slugTitle,
                  style: context.qioText.bodyMedium.copyWith(
                    color: context.qio.textPrimary,
                  ),
                ),
                Text(
                  current == null
                      ? l10n.slugNone
                      : shortUrl(current).replaceFirst('https://', ''),
                  style: context.qioText.caption,
                ),
              ],
            ),
          ),
          Icon(Icons.edit_outlined, size: 18, color: context.qio.gray500),
        ],
      ),
    );
  }
}

class _SlugResult {
  const _SlugResult({required this.removed});

  final bool removed;
}

class _SlugDialog extends StatefulWidget {
  const _SlugDialog({
    required this.queueId,
    required this.currentSlug,
    required this.service,
  });

  final String queueId;
  final String? currentSlug;
  final QueueService service;

  @override
  State<_SlugDialog> createState() => _SlugDialogState();
}

class _SlugDialogState extends State<_SlugDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.currentSlug ?? '',
  );
  final _formKey = GlobalKey<FormState>();
  String? _takenSlug;
  String? _failure;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String? value, AppLocalizations l10n) {
    final format = validateSlugInput(value, l10n);
    if (format != null) return format;
    final text = normalizeSlug(value ?? '');
    if (text.isNotEmpty && text == _takenSlug) return l10n.slugTakenError;
    return null;
  }

  Future<void> _save({required bool remove}) async {
    final l10n = AppLocalizations.of(context);
    if (!remove && !_formKey.currentState!.validate()) return;
    final text = remove ? '' : normalizeSlug(_controller.text);
    final next = text.isEmpty ? null : text;
    if (next == widget.currentSlug) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _saving = true;
      _failure = null;
    });
    try {
      await widget.service.setSlug(
        widget.queueId,
        currentSlug: widget.currentSlug,
        newSlug: next,
      );
      if (!mounted) return;
      Navigator.of(context).pop(_SlugResult(removed: next == null));
    } on SlugTaken {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _takenSlug = next;
      });
      _formKey.currentState!.validate();
    } on Exception {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _failure = l10n.genericActionError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.slugTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QioInput(
                label: l10n.slugDialogLabel,
                hint: l10n.slugDialogHint,
                controller: _controller,
                keyboardType: TextInputType.url,
                autofocus: true,
                enabled: !_saving,
                validator: (v) => _validate(v, l10n),
                onChanged: (_) => setState(() => _failure = null),
              ),
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  l10n.slugPreview(
                    shortUrl(
                      normalizeSlug(_controller.text).isEmpty
                          ? slugPlaceholder
                          : normalizeSlug(_controller.text),
                    ).replaceFirst('https://', ''),
                  ),
                  style: context.qioText.caption,
                ),
              ),
              if (_failure != null) ...[
                const SizedBox(height: 8),
                Text(
                  _failure!,
                  style: context.qioText.caption.copyWith(
                    color: QioColors.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        if (widget.currentSlug != null)
          TextButton(
            onPressed: _saving ? null : () => _save(remove: true),
            child: Text(l10n.slugRemove),
          ),
        TextButton(
          onPressed: _saving ? null : () => _save(remove: false),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

const slugPlaceholder = '...';
