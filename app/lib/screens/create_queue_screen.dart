import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/qio_button.dart';
import '../widgets/qio_input.dart';
import '../widgets/qio_responsive_body.dart';
import 'queue_panel_screen.dart';

class CreateQueueScreen extends StatefulWidget {
  const CreateQueueScreen({super.key});

  @override
  State<CreateQueueScreen> createState() => _CreateQueueScreenState();
}

class _CreateQueueScreenState extends State<CreateQueueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  bool _isLoading = false;

  bool get _dirty =>
      _nameCtrl.text.trim().isNotEmpty ||
      _descCtrl.text.trim().isNotEmpty ||
      _timeCtrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    for (final c in [_nameCtrl, _descCtrl, _timeCtrl]) {
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
    super.dispose();
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final queue = await QueueService.instance.createQueue(
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim(),
        avgServiceMin: int.tryParse(_timeCtrl.text.trim()) ?? 15,
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
          backgroundColor: QioColors.surface,
          leading: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.backWithArrow,
              style: QioTextStyles.body.copyWith(
                fontSize: 16,
                color: QioColors.primary,
              ),
            ),
          ),
          leadingWidth: 100,
          title: Text(
            l10n.newQueue,
            style: QioTextStyles.heading2.copyWith(
              fontWeight: FontWeight.w700,
              color: QioColors.textPrimary,
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
                    QioInput(
                      label: l10n.queueNameLabel,
                      hint: l10n.queueNameHint,
                      controller: _nameCtrl,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l10n.queueNameRequired
                          : null,
                    ),
                    const SizedBox(height: 24),
                    QioInput(
                      label: l10n.descriptionLabel,
                      hint: l10n.descriptionHint,
                      controller: _descCtrl,
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    QioInput(
                      label: l10n.avgServiceLabel,
                      hint: '15',
                      controller: _timeCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n <= 0) return l10n.invalidNumber;
                        return null;
                      },
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
