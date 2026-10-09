import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../services/account_format.dart';
import '../services/action_errors.dart';
import '../services/auth_service.dart';
import '../services/data_subject_service.dart';
import '../theme/qio_palette.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/qio_button.dart';
import '../widgets/qio_card.dart';
import '../widgets/qio_responsive_body.dart';
import '../widgets/queue_panel/add_person_dialog.dart';

typedef CsvSharer = Future<void> Function(String csv, String fileName);

Future<void> shareCustomerCsv(String csv, String fileName) async {
  final bytes = Uint8List.fromList(utf8.encode(csv));
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'text/csv', name: fileName)],
      fileNameOverrides: [fileName],
    ),
  );
}

class DataSubjectScreen extends StatefulWidget {
  const DataSubjectScreen({
    super.key,
    this.service,
    this.auth,
    this.shareCsv = shareCustomerCsv,
  });

  final DataSubjectService? service;
  final AuthService? auth;
  final CsvSharer shareCsv;

  @override
  State<DataSubjectScreen> createState() => _DataSubjectScreenState();
}

class _DataSubjectScreenState extends State<DataSubjectScreen> {
  final _phone = TextEditingController();
  late final DataSubjectService _service =
      widget.service ?? DataSubjectService.instance;
  late final AuthService _auth = widget.auth ?? AuthService.instance;

  bool _busy = false;
  String? _digits;
  CustomerSummary? _summary;
  String? _message;
  bool _messageIsError = false;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  String? get _typedDigits => normalizeCustomerPhone(_phone.text);

  void _setMessage(String? text, {bool error = false}) {
    _message = text;
    _messageIsError = error;
  }

  String _errorText(Object e) {
    final l10n = AppLocalizations.of(context);
    if (e is FirebaseException && e.code == 'resource-exhausted') {
      return l10n.dataSubjectRateLimited;
    }
    return describeActionError(e).message(l10n);
  }

  Future<T?> _run<T>(Future<T> Function() action) async {
    setState(() {
      _busy = true;
      _setMessage(null);
    });
    try {
      return await _withReauth(action);
    } on Exception catch (e) {
      if (mounted) setState(() => _setMessage(_errorText(e), error: true));
      return null;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<T> _withReauth<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      if (e.code != 'recent-login' || !mounted) rethrow;
      final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ReauthDialog(auth: _auth),
      );
      if (ok != true) rethrow;
      return action();
    }
  }

  Future<void> _search() async {
    final digits = _typedDigits;
    if (digits == null || _busy) return;
    final summary = await _run(() => _service.find(digits));
    if (summary == null || !mounted) return;
    setState(() {
      _digits = digits;
      _summary = summary;
    });
  }

  Future<void> _export() async {
    final digits = _digits;
    if (digits == null || _busy) return;
    final l10n = AppLocalizations.of(context);
    final result = await _run(() => _service.export(digits));
    if (result == null || !mounted) return;
    await widget.shareCsv(result.csv, 'qio-dados-cliente.csv');
    if (!mounted) return;
    if (result.truncated) {
      setState(() => _setMessage(l10n.dataSubjectExportTruncated));
    }
  }

  Future<void> _erase(CustomerEraseMode mode) async {
    final digits = _digits;
    if (digits == null || _busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmEraseDialog(digits: digits, mode: mode),
    );
    if (confirmed != true || !mounted) return;
    final l10n = AppLocalizations.of(context);
    final result = await _run(() => _service.erase(digits, mode));
    if (result == null || !mounted) return;
    setState(() {
      _summary = null;
      _digits = null;
      _phone.clear();
      _setMessage(
        result.complete
            ? l10n.dataSubjectDone(result.total)
            : l10n.dataSubjectPartial,
        error: !result.complete,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summary = _summary;
    return Scaffold(
      backgroundColor: context.qio.gray100,
      appBar: AppBar(
        backgroundColor: context.qio.surface,
        title: Text(
          l10n.dataSubjectTitle,
          style: context.qioText.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: context.qio.textPrimary,
          ),
        ),
      ),
      body: QioResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.dataSubjectSubtitle,
              style: context.qioText.body.copyWith(
                color: context.qio.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            QioCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _phone,
                    enabled: !_busy,
                    keyboardType: TextInputType.phone,
                    inputFormatters: const [BrPhoneFormatter()],
                    autofillHints: const [AutofillHints.telephoneNumber],
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: l10n.dataSubjectPhoneLabel,
                      hintText: '(11) 99999-9999',
                    ),
                    onChanged: (_) => setState(() {
                      if (_typedDigits != _digits) {
                        _summary = null;
                        _digits = null;
                      }
                    }),
                    onSubmitted: (_) => _search(),
                  ),
                  const SizedBox(height: 12),
                  QioButton(
                    label: l10n.dataSubjectSearch,
                    icon: Icons.search,
                    isFullWidth: true,
                    isLoading: _busy,
                    onPressed: _typedDigits == null || _busy ? null : _search,
                  ),
                ],
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Text(
                  _message!,
                  style: context.qioText.bodyMedium.copyWith(
                    color: _messageIsError
                        ? Theme.of(context).colorScheme.error
                        : context.qio.textPrimary,
                  ),
                ),
              ),
            ],
            if (summary != null) ...[
              const SizedBox(height: 12),
              ..._buildSummary(l10n, summary),
            ],
            const SizedBox(height: 16),
            Text(
              l10n.dataSubjectAuditNote,
              style: context.qioText.caption.copyWith(
                color: context.qio.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSummary(AppLocalizations l10n, CustomerSummary summary) {
    if (summary.isEmpty) {
      return [
        Semantics(
          liveRegion: true,
          child: QioCard(
            child: Text(l10n.dataSubjectNone, style: context.qioText.body),
          ),
        ),
      ];
    }
    return [
      Semantics(
        liveRegion: true,
        header: true,
        child: Text(
          l10n.dataSubjectFound(summary.queues.length),
          style: context.qioText.bodyMedium,
        ),
      ),
      const SizedBox(height: 8),
      for (final q in summary.queues) ...[
        QioCard(
          child: Semantics(
            container: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q.queueName.isEmpty ? q.queueId : q.queueName,
                  style: context.qioText.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.dataSubjectQueueCounts(q.history, q.feedback, q.entries),
                  style: context.qioText.body.copyWith(
                    color: context.qio.textSecondary,
                  ),
                ),
                if (q.firstAt != null && q.lastAt != null)
                  Text(
                    l10n.dataSubjectPeriod(
                      formatMemberSince(q.firstAt!),
                      formatMemberSince(q.lastAt!),
                    ),
                    style: context.qioText.caption.copyWith(
                      color: context.qio.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 4),
      QioButton(
        label: l10n.dataSubjectExport,
        icon: Icons.download,
        variant: QioButtonVariant.secondary,
        isFullWidth: true,
        onPressed: _busy ? null : _export,
      ),
      const SizedBox(height: 8),
      QioButton(
        label: l10n.dataSubjectAnonymize,
        variant: QioButtonVariant.dangerSoft,
        isFullWidth: true,
        onPressed: _busy ? null : () => _erase(CustomerEraseMode.anonymize),
      ),
      const SizedBox(height: 8),
      QioButton(
        label: l10n.dataSubjectDelete,
        variant: QioButtonVariant.danger,
        isFullWidth: true,
        onPressed: _busy ? null : () => _erase(CustomerEraseMode.delete),
      ),
    ];
  }
}

class _ConfirmEraseDialog extends StatefulWidget {
  const _ConfirmEraseDialog({required this.digits, required this.mode});

  final String digits;
  final CustomerEraseMode mode;

  @override
  State<_ConfirmEraseDialog> createState() => _ConfirmEraseDialogState();
}

class _ConfirmEraseDialogState extends State<_ConfirmEraseDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _matches =>
      normalizeCustomerPhone(_controller.text) == widget.digits;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final delete = widget.mode == CustomerEraseMode.delete;
    return AlertDialog(
      title: Text(
        delete
            ? l10n.dataSubjectConfirmTitleDelete
            : l10n.dataSubjectConfirmTitleAnonymize,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              delete
                  ? l10n.dataSubjectConfirmBodyDelete
                  : l10n.dataSubjectConfirmBodyAnonymize,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.phone,
              inputFormatters: const [BrPhoneFormatter()],
              decoration: InputDecoration(
                labelText: l10n.dataSubjectConfirmLabel,
                hintText: '(11) 99999-9999',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _matches ? () => Navigator.of(context).pop(true) : null,
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(l10n.dataSubjectConfirmButton),
        ),
      ],
    );
  }
}

class _ReauthDialog extends StatefulWidget {
  const _ReauthDialog({required this.auth});

  final AuthService auth;

  @override
  State<_ReauthDialog> createState() => _ReauthDialogState();
}

class _ReauthDialogState extends State<_ReauthDialog> {
  final _password = TextEditingController();
  bool _working = false;
  String? _error;

  bool get _usesPassword => widget.auth.hasPasswordProvider;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      if (_usesPassword) {
        await widget.auth.reauthenticateWithPassword(_password.text);
      } else {
        await widget.auth.reauthenticateWithGoogle();
      }
      if (mounted) Navigator.of(context).pop(true);
    } on Exception {
      if (!mounted) return;
      setState(() {
        _working = false;
        _error = l10n.deleteAccountReauthFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.dataSubjectReauthTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_usesPassword)
            TextField(
              controller: _password,
              enabled: !_working,
              obscureText: true,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.deleteAccountPasswordLabel,
              ),
              onChanged: (_) => setState(() {}),
            )
          else
            Text(l10n.dataSubjectReauthHint),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _working ? null : () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _working || (_usesPassword && _password.text.isEmpty)
              ? null
              : _submit,
          child: Text(l10n.dataSubjectReauthButton),
        ),
      ],
    );
  }
}
