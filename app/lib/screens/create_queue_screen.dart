import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/queue_info.dart';
import '../models/queue_slot.dart';
import '../services/group_service.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/group_picker.dart';
import '../widgets/qio_button.dart';
import '../widgets/qio_input.dart';
import '../widgets/queue_info_fields.dart';
import '../widgets/queue_panel/panel_notices.dart';
import '../widgets/queue_panel/queue_limit_tile.dart';
import '../widgets/queue_panel/slots_editor.dart';
import '../widgets/qio_responsive_body.dart';
import 'queue_panel_screen.dart';
import '../theme/qio_palette.dart';

class CreateQueueScreen extends StatefulWidget {
  const CreateQueueScreen({super.key, this.queues, this.groups});

  final QueueService? queues;
  final GroupService? groups;

  @override
  State<CreateQueueScreen> createState() => _CreateQueueScreenState();
}

class _CreateQueueScreenState extends State<CreateQueueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  final _advancedCtrl = ExpansibleController();
  bool _isLoading = false;
  String? _groupId;
  QueueMode _mode = QueueMode.queue;
  List<QueueSlot> _slots = [];
  SlotsError? _slotsError;

  bool get _dirty =>
      _nameCtrl.text.trim().isNotEmpty ||
      _descCtrl.text.trim().isNotEmpty ||
      _timeCtrl.text.trim().isNotEmpty ||
      _limitCtrl.text.trim().isNotEmpty ||
      _mode == QueueMode.schedule;

  @override
  void initState() {
    super.initState();
    for (final c in [_nameCtrl, _descCtrl, _timeCtrl, _limitCtrl]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.discardTitle),
        content: Text(l10n.discardBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.keepEditing),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _timeCtrl.dispose();
    _limitCtrl.dispose();
    super.dispose();
  }

  bool _advancedHasError(AppLocalizations l10n) {
    final time = _timeCtrl.text.trim();
    return QueueInfo.validateDescription(_descCtrl.text) != null ||
        (time.isNotEmpty &&
            QueueInfo.validateAvgServiceMin(
                  QueueInfo.parseAvgServiceMin(time),
                ) !=
                null) ||
        validateMaxWaiting(_limitCtrl.text, l10n) != null;
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    final formOk = _formKey.currentState!.validate();
    final slotsError = validateSlots(_mode, _slots);
    setState(() => _slotsError = slotsError);
    if (!formOk || slotsError != null) {
      if (slotsError != null || _advancedHasError(l10n)) {
        _advancedCtrl.expand();
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      final queue = await (widget.queues ?? QueueService.instance).createQueue(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        avgServiceMin: QueueInfo.parseAvgServiceMin(_timeCtrl.text),
        maxWaiting: int.tryParse(_limitCtrl.text.trim()) ?? 0,
        groupId: _groupId,
        mode: _mode,
        slots: sortedSlots(_slots),
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                QueuePanelScreen(queueId: queue.id, queueName: queue.name),
          ),
        );
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).genericActionError),
            backgroundColor: QioColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !_dirty || _isLoading,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: context.qio.surface,
          leading: const QueueBackButton(),
          title: Text(
            l10n.newQueue,
            style: context.qioText.heading2.copyWith(
              fontWeight: FontWeight.w700,
              color: context.qio.textPrimary,
            ),
          ),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: QioButton(
                label: l10n.create,
                onPressed: _isLoading ? null : _create,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        body: QioResponsiveBody(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    QueueNameField(controller: _nameCtrl, enabled: !_isLoading),
                    const SizedBox(height: 16),
                    Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        controller: _advancedCtrl,
                        maintainState: true,
                        tilePadding: EdgeInsets.zero,
                        childrenPadding: const EdgeInsets.only(bottom: 8),
                        title: Text(
                          l10n.advancedOptions,
                          style: context.qioText.bodyMedium.copyWith(
                            color: context.qio.textPrimary,
                          ),
                        ),
                        children: [
                          QueueDescriptionField(
                            controller: _descCtrl,
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 24),
                          QueueAvgServiceField(
                            controller: _timeCtrl,
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 16),
                          QioInput(
                            label: l10n.maxWaitingLabel,
                            hint: l10n.maxWaitingHint,
                            controller: _limitCtrl,
                            keyboardType: TextInputType.number,
                            validator: (v) => validateMaxWaiting(v, l10n),
                          ),
                          const SizedBox(height: 16),
                          GroupPicker(
                            value: _groupId,
                            groups: widget.groups,
                            enabled: !_isLoading,
                            onChanged: (id) => setState(() => _groupId = id),
                          ),
                          const SizedBox(height: 16),
                          SlotsEditor(
                            mode: _mode,
                            slots: _slots,
                            error: _slotsError,
                            enabled: !_isLoading,
                            onChanged: (mode, slots) => setState(() {
                              _mode = mode;
                              _slots = slots;
                              _slotsError = null;
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    QioButton(
                      label: l10n.createQueue,
                      onPressed: _create,
                      isLoading: _isLoading,
                      isFullWidth: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
