import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/action_errors.dart';
import '../services/auth_service.dart';
import '../services/delete_service.dart';

enum _Stage { input, working, reauthFailed, failed }

class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({
    super.key,
    required this.auth,
    required this.email,
    required this.deleteService,
  });

  final AuthService auth;
  final String? email;
  final DeleteService deleteService;

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _confirm = TextEditingController();
  final _password = TextEditingController();
  _Stage _stage = _Stage.input;
  bool _reauthenticated = false;
  String? _errorText;

  bool get _usesPassword => widget.auth.hasPasswordProvider;

  bool get _canSubmit {
    if (!deleteConfirmationMatches(_confirm.text, email: widget.email)) {
      return false;
    }
    return !_usesPassword || _password.text.isNotEmpty;
  }

  @override
  void dispose() {
    _confirm.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _stage = _Stage.working;
      _errorText = null;
    });
    if (!_reauthenticated) {
      try {
        if (_usesPassword) {
          await widget.auth.reauthenticateWithPassword(_password.text);
        } else {
          await widget.auth.reauthenticateWithGoogle();
        }
        _reauthenticated = true;
      } on Exception catch (_) {
        if (!mounted) return;
        setState(() {
          _stage = _Stage.reauthFailed;
          _errorText = l10n.deleteAccountReauthFailed;
        });
        return;
      }
    }
    try {
      await widget.deleteService.deleteAccount();
      if (mounted) Navigator.of(context).pop(true);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.failed;
        _errorText =
            e is FirebaseException &&
                describeActionError(e) == ActionError.offline
            ? l10n.actionErrorOffline
            : l10n.deleteAccountError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final working = _stage == _Stage.working;
    final failed = _stage == _Stage.failed;
    return PopScope(
      canPop: !working,
      child: AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.deleteAccountWarning),
              const SizedBox(height: 16),
              TextField(
                controller: _confirm,
                enabled: !working && !failed,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.deleteAccountConfirmLabel,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              if (_usesPassword)
                TextField(
                  controller: _password,
                  enabled: !working && !failed,
                  obscureText: true,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l10n.deleteAccountPasswordLabel,
                  ),
                  onChanged: (_) => setState(() {}),
                )
              else
                Text(l10n.deleteAccountGoogleHint),
              if (working) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(l10n.deleteAccountProgress)),
                  ],
                ),
              ],
              if (_errorText != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorText!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: working ? null : () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: working || !_canSubmit ? null : _submit,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              failed
                  ? l10n.deleteAccountRetry
                  : l10n.deleteAccountConfirmButton,
            ),
          ),
        ],
      ),
    );
  }
}
