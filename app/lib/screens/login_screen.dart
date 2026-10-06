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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
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
        await AuthService.instance.signUpWithEmail(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
      } else {
        await AuthService.instance.signInWithEmail(
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showAuthError(e.code);
    } on Exception {
      if (mounted) _showAuthError('');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _google() async {
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signInWithGoogle();
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    label: 'Qio',
                    child: SvgPicture.asset(
                      QioColors.isDark
                          ? 'assets/brand/logo-dark.svg'
                          : 'assets/brand/logo.svg',
                      height: 72,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.loginTagline,
                    style: QioTextStyles.body.copyWith(
                      fontSize: 16,
                      color: QioColors.gray700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (_isSignUp)
                    QioInput(
                      label: l10n.nameLabel,
                      hint: l10n.nameHint,
                      controller: _nameCtrl,
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
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.emailRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  QioInput(
                    label: l10n.passwordLabel,
                    hint: '••••••••',
                    controller: _passwordCtrl,
                    obscureText: true,
                    validator: (v) =>
                        (v == null || v.length < 6) ? l10n.passwordMin : null,
                  ),
                  const SizedBox(height: 24),
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
                          color: QioColors.gray100,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          l10n.orSeparator,
                          style: QioTextStyles.caption.copyWith(
                            color: QioColors.gray400,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: QioColors.gray100,
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
                      _isSignUp ? l10n.haveAccountSignIn : l10n.createAccount,
                      style: QioTextStyles.body.copyWith(
                        fontSize: 14,
                        color: QioColors.primaryText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
