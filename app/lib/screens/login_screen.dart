import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_errors.dart';
import '../services/auth_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/qio_button.dart';
import '../widgets/qio_input.dart';
import '../widgets/qio_responsive_body.dart';
import '../theme/qio_palette.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.auth});

  final AuthService? auth;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  AuthService get _auth => widget.auth ?? AuthService.instance;
  bool _isLoading = false;
  bool _isSignUp = false;
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      if (_isSignUp) {
        await _auth.signUpWithEmail(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      } else {
        await _auth.signInWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showAuthError(e.code);
    } on Exception {
      if (mounted) _showAuthError('');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final l10n = AppLocalizations.of(context);
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showError(l10n.resetEmailRequired);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _auth.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.resetEmailSent)));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.resetEmailSent)));
      } else {
        _showAuthError(e.code);
      }
    } on Exception {
      if (mounted) _showAuthError('');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _google() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (mounted) _showAuthError(e.code);
    } on Exception {
      if (mounted) _showAuthError('');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAuthError(String code) {
    _showError(authErrorMessage(AppLocalizations.of(context), code));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: QioColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: QioResponsiveBody(
        maxWidth: 440,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        label: 'Qio',
                        child: SvgPicture.asset(
                          Theme.of(context).brightness == Brightness.dark
                              ? 'assets/brand/logo-dark.svg'
                              : 'assets/brand/logo.svg',
                          height: 72,
                          excludeFromSemantics: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.loginTagline,
                        style: context.qioText.body.copyWith(
                          fontSize: 16,
                          color: context.qio.gray700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      if (_isSignUp)
                        QioInput(
                          label: l10n.nameLabel,
                          hint: l10n.nameHint,
                          controller: _nameCtrl,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? l10n.nameRequired
                              : null,
                        ),
                      if (_isSignUp) const SizedBox(height: 16),
                      QioInput(
                        label: l10n.emailLabel,
                        hint: l10n.emailHint,
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.emailRequired
                            : null,
                      ),
                      const SizedBox(height: 16),
                      QioPasswordInput(
                        label: l10n.passwordLabel,
                        hint: '••••••••',
                        controller: _passwordCtrl,
                        textInputAction: TextInputAction.done,
                        autofillHints: [
                          _isSignUp
                              ? AutofillHints.newPassword
                              : AutofillHints.password,
                        ],
                        onSubmitted: (_) => _submit(),
                        validator: (v) => (v == null || v.length < 6)
                            ? l10n.passwordMin
                            : null,
                      ),
                      if (!_isSignUp)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading ? null : _forgotPassword,
                            child: Text(l10n.forgotPassword),
                          ),
                        ),
                      const SizedBox(height: 12),
                      QioButton(
                        label: _isSignUp ? l10n.createAccount : l10n.signIn,
                        onPressed: _submit,
                        isLoading: _isLoading,
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              height: 1,
                              thickness: 1,
                              color: context.qio.gray100,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              l10n.orSeparator,
                              style: context.qioText.caption.copyWith(
                                color: context.qio.gray400,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              height: 1,
                              thickness: 1,
                              color: context.qio.gray100,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      QioButton(
                        label: l10n.continueWithGoogle,
                        variant: QioButtonVariant.secondary,
                        icon: Icons.g_mobiledata,
                        onPressed: _google,
                        isFullWidth: true,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(
                          _isSignUp
                              ? l10n.haveAccountSignIn
                              : l10n.createAccount,
                          style: context.qioText.body.copyWith(
                            fontSize: 14,
                            color: context.qio.primaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
