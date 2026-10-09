import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/queue_info.dart';
import '../services/queue_service.dart';
import 'qio_input.dart';

String? queueInfoErrorText(QueueInfoError? error, AppLocalizations l10n) =>
    switch (error) {
      null => null,
      QueueInfoError.nameRequired => l10n.queueNameRequired,
      QueueInfoError.nameTooLong => l10n.queueNameTooLong,
      QueueInfoError.descriptionTooLong => l10n.descriptionTooLong,
      QueueInfoError.avgServiceInvalid => l10n.avgServiceInvalid,
    };

String queueErrorMessage(Object error, AppLocalizations l10n) {
  if (error is QueueLimitReached) {
    return l10n.queueLimitReached(maxQueuesPerOwner);
  }
  if (error is FormatException) {
    final info = QueueInfoError.values.asNameMap()[error.message];
    if (info != null) return queueInfoErrorText(info, l10n)!;
  }
  return l10n.genericActionError;
}

class QueueNameField extends StatelessWidget {
  const QueueNameField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.initial,
    this.autofocus = false,
    this.onSubmitted,
    this.textInputAction,
  });

  final TextEditingController controller;
  final bool enabled;
  final String? initial;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return QioInput(
      label: l10n.queueNameLabel,
      hint: l10n.queueNameHint,
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      onSubmitted: onSubmitted,
      textInputAction: textInputAction,
      validator: (v) => initial != null && v?.trim() == initial!.trim()
          ? null
          : queueInfoErrorText(QueueInfo.validateName(v), l10n),
    );
  }
}

class QueueDescriptionField extends StatelessWidget {
  const QueueDescriptionField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.initial,
  });

  final TextEditingController controller;
  final bool enabled;
  final String? initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return QioInput(
      label: l10n.descriptionLabel,
      hint: l10n.descriptionHint,
      controller: controller,
      enabled: enabled,
      maxLines: 4,
      validator: (v) => (v?.trim() ?? '') == (initial?.trim() ?? '')
          ? null
          : queueInfoErrorText(QueueInfo.validateDescription(v), l10n),
    );
  }
}

class QueueAvgServiceField extends StatelessWidget {
  const QueueAvgServiceField({
    super.key,
    required this.controller,
    this.required = false,
    this.enabled = true,
    this.initial,
  });

  final TextEditingController controller;
  final bool required;
  final bool enabled;
  final int? initial;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return QioInput(
      label: l10n.avgServiceLabel,
      hint: '$defaultAvgServiceMin',
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      validator: (v) {
        if (!required && (v == null || v.trim().isEmpty)) return null;
        if (initial != null && QueueInfo.parseAvgServiceMin(v) == initial) {
          return null;
        }
        return queueInfoErrorText(
          QueueInfo.validateAvgServiceMin(QueueInfo.parseAvgServiceMin(v)),
          l10n,
        );
      },
    );
  }
}
