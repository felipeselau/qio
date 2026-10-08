import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/queue_slot.dart';
import '../../services/manual_entry_service.dart';
import '../../theme/qio_palette.dart';
import '../../theme/qio_text_styles.dart';

class ManualAddResult {
  const ManualAddResult({required this.name, required this.ticket});

  final String name;
  final int ticket;
}

final RegExp _phonePattern = RegExp(r'^\(\d{2}\) \d{4,5}-\d{4}$');

bool isValidManualPhone(String value) =>
    value.isEmpty || _phonePattern.hasMatch(value);

String formatBrPhone(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  final d = digits.length > 11 ? digits.substring(0, 11) : digits;
  if (d.isEmpty) return '';
  if (d.length <= 2) return '($d';
  final area = d.substring(0, 2);
  final rest = d.substring(2);
  if (rest.length <= 4) return '($area) $rest';
  final split = d.length == 11 ? 5 : 4;
  if (rest.length <= split) return '($area) $rest';
  return '($area) ${rest.substring(0, split)}-${rest.substring(split)}';
}

class BrPhoneFormatter extends TextInputFormatter {
  const BrPhoneFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = formatBrPhone(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

Future<ManualAddResult?> showAddPersonDialog(
  BuildContext context, {
  required String queueId,
  required ManualEntryService service,
  List<QueueSlot> slots = const [],
  bool scheduled = false,
}) {
  return showDialog<ManualAddResult>(
    context: context,
    builder: (_) => AddPersonDialog(
      queueId: queueId,
      service: service,
      slots: slots,
      scheduled: scheduled,
    ),
  );
}

class AddPersonDialog extends StatefulWidget {
  const AddPersonDialog({
    super.key,
    required this.queueId,
    required this.service,
    this.slots = const [],
    this.scheduled = false,
  });

  final String queueId;
  final ManualEntryService service;
  final List<QueueSlot> slots;
  final bool scheduled;

  @override
  State<AddPersonDialog> createState() => _AddPersonDialogState();
}

class _AddPersonDialogState extends State<AddPersonDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String? _slotId;
  bool _loading = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  String get _trimmedName => _name.text.trim();

  bool get _nameValid => _trimmedName.isNotEmpty && _trimmedName.length <= 60;

  bool get _phoneValid => isValidManualPhone(_phone.text.trim());

  bool get _slotValid => !widget.scheduled || _slotId != null;

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_nameValid || !_phoneValid || !_slotValid) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _loading = true);
    try {
      final ticket = await widget.service.add(
        queueId: widget.queueId,
        name: _trimmedName,
        phone: _phone.text.trim(),
        slotId: widget.scheduled ? _slotId : null,
      );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pop(ManualAddResult(name: _trimmedName, ticket: ticket));
    } on ManualEntryException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.error.message(l10n);
      });
    } on Exception {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = l10n.genericActionError;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.addPersonTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.addPersonHint, style: context.qioText.caption),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              enabled: !_loading,
              autofocus: true,
              maxLength: 60,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.nameLabel,
                errorText: _submitted && !_nameValid
                    ? l10n.manualNameRequired
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phone,
              enabled: !_loading,
              keyboardType: TextInputType.phone,
              inputFormatters: const [BrPhoneFormatter()],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: l10n.manualPhoneLabel,
                hintText: '(00) 00000-0000',
                errorText: _submitted && !_phoneValid
                    ? l10n.manualPhoneInvalid
                    : null,
              ),
            ),
            if (widget.scheduled) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _slotId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.manualSlotLabel,
                  errorText: _submitted && !_slotValid
                      ? l10n.manualSlotRequiredField
                      : null,
                ),
                items: [
                  for (final slot in widget.slots)
                    DropdownMenuItem(
                      value: slot.id,
                      child: Text(
                        l10n.manualSlotOption(slot.start, slot.capacity),
                      ),
                    ),
                ],
                onChanged: _loading
                    ? null
                    : (value) => setState(() => _slotId = value),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: context.qioText.caption.copyWith(
                  color: context.qio.statusClosedText,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.manualAddConfirm),
        ),
      ],
    );
  }
}
