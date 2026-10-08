import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/qio_text_styles.dart';
import '../theme/qio_palette.dart';

class QioInput extends StatelessWidget {
  const QioInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.textInputAction,
    this.autofillHints,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: context.qioText.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          maxLines: maxLines,
          enabled: enabled,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          onFieldSubmitted: onSubmitted,
          focusNode: focusNode,
          autofocus: autofocus,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: context.qio.gray400)
                : null,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

class QioPasswordInput extends StatefulWidget {
  const QioPasswordInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.validator,
    this.textInputAction,
    this.autofillHints = const [AutofillHints.password],
    this.onSubmitted,
    this.focusNode,
  });

  final String label;
  final String? hint;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final Iterable<String> autofillHints;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;

  @override
  State<QioPasswordInput> createState() => _QioPasswordInputState();
}

class _QioPasswordInputState extends State<QioPasswordInput> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return QioInput(
      label: widget.label,
      hint: widget.hint,
      controller: widget.controller,
      obscureText: !_visible,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      onSubmitted: widget.onSubmitted,
      focusNode: widget.focusNode,
      keyboardType: TextInputType.visiblePassword,
      suffixIcon: IconButton(
        tooltip: _visible ? l10n.hidePassword : l10n.showPassword,
        icon: Icon(
          _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: context.qio.gray500,
        ),
        onPressed: () => setState(() => _visible = !_visible),
      ),
    );
  }
}
