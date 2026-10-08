import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/queue.dart';
import '../models/queue_info.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_palette.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/qio_button.dart';
import '../widgets/qio_responsive_body.dart';
import '../widgets/queue_info_fields.dart';
import '../widgets/queue_panel/panel_notices.dart';

class EditQueueScreen extends StatefulWidget {
  const EditQueueScreen({super.key, required this.queue, this.queues});

  final Queue queue;
  final QueueService? queues;

  @override
  State<EditQueueScreen> createState() => _EditQueueScreenState();
}

class _EditQueueScreenState extends State<EditQueueScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.queue.name);
  late final _descCtrl = TextEditingController(
    text: widget.queue.description ?? '',
  );
  late final _timeCtrl = TextEditingController(
    text: '${widget.queue.avgServiceMin}',
  );
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await (widget.queues ?? QueueService.instance).updateQueueInfo(
        widget.queue.id,
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        avgServiceMin: QueueInfo.parseAvgServiceMin(_timeCtrl.text)!,
      );
      messenger.showSnackBar(SnackBar(content: Text(l10n.queueUpdated)));
      navigator.pop();
    } on Exception {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.genericActionError),
          backgroundColor: QioColors.error,
        ),
      );
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: context.qio.surface,
          leading: const QueueBackButton(),
          title: Text(
            l10n.editQueue,
            style: context.qioText.heading2.copyWith(
              fontWeight: FontWeight.w700,
              color: context.qio.textPrimary,
            ),
          ),
          centerTitle: true,
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
                    QueueNameField(controller: _nameCtrl, enabled: !_saving),
                    const SizedBox(height: 24),
                    QueueDescriptionField(
                      controller: _descCtrl,
                      enabled: !_saving,
                    ),
                    const SizedBox(height: 24),
                    QueueAvgServiceField(
                      controller: _timeCtrl,
                      required: true,
                      enabled: !_saving,
                    ),
                    const SizedBox(height: 32),
                    QioButton(
                      label: l10n.save,
                      onPressed: _save,
                      isLoading: _saving,
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
