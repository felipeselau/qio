import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/operator.dart';
import '../services/operator_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/qio_button.dart';
import '../widgets/qio_card.dart';
import '../widgets/qio_input.dart';
import 'queue_panel_screen.dart';
import '../widgets/qio_skeleton.dart';

class JoinOperatorScreen extends StatefulWidget {
  const JoinOperatorScreen({super.key, this.initialCode});

  final String? initialCode;

  @override
  State<JoinOperatorScreen> createState() => _JoinOperatorScreenState();
}

class _JoinOperatorScreenState extends State<JoinOperatorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeCtrl = TextEditingController(
    text: widget.initialCode,
  );
  bool _isLoading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final request = await OperatorService.instance.requestToJoinAsOperator(
        _codeCtrl.text,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OperatorPendingScreen(
              queueId: request.queueId,
              queueName: request.queueName,
            ),
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is OperatorInviteException
                  ? e.message(AppLocalizations.of(context))
                  : AppLocalizations.of(context).sendRequestError,
            ),
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: QioColors.surface,
        title: Text(
          l10n.joinAsOperator,
          style: QioTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: QioColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.joinOperatorIntro,
                  style: QioTextStyles.body.copyWith(
                    color: QioColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                QioInput(
                  label: l10n.inviteCodeLabel,
                  hint: l10n.inviteCodeHint,
                  controller: _codeCtrl,
                  prefixIcon: Icons.vpn_key_outlined,
                  validator: (v) =>
                      OperatorService.normalizeCode(v ?? '').length != 6
                      ? l10n.inviteCodeLength
                      : null,
                ),
                const SizedBox(height: 32),
                QioButton(
                  label: l10n.sendRequest,
                  onPressed: _isLoading ? null : _submit,
                  isLoading: _isLoading,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OperatorPendingScreen extends StatefulWidget {
  const OperatorPendingScreen({
    super.key,
    required this.queueId,
    required this.queueName,
  });

  final String queueId;
  final String queueName;

  @override
  State<OperatorPendingScreen> createState() => _OperatorPendingScreenState();
}

class _OperatorPendingScreenState extends State<OperatorPendingScreen> {
  late final Stream<OperatorRequest?> _requestStream = OperatorService.instance
      .watchMyRequest(widget.queueId);
  bool _cancelLoading = false;

  Future<void> _cancel() async {
    setState(() => _cancelLoading = true);
    try {
      await OperatorService.instance.cancelMyRequest(widget.queueId);
      if (mounted) Navigator.of(context).pop();
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).cancelRequestError),
            backgroundColor: QioColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cancelLoading = false);
    }
  }

  void _openQueue() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QueuePanelScreen(
          queueId: widget.queueId,
          queueName: widget.queueName,
          isOwner: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: QioColors.gray100,
      appBar: AppBar(
        backgroundColor: QioColors.surface,
        title: Text(
          widget.queueName,
          style: QioTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: QioColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<OperatorRequest?>(
        stream: _requestStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const QioSkeletonList(count: 2);
          }
          final request = snap.data;
          final (icon, color, title, subtitle) = switch (request?.status) {
            OperatorRequestStatus.pending => (
              Icons.hourglass_top,
              QioColors.warning,
              l10n.awaitingApproval,
              l10n.pendingBody,
            ),
            OperatorRequestStatus.approved => (
              Icons.check_circle_outline,
              QioColors.success,
              l10n.requestApproved,
              l10n.approvedBody,
            ),
            OperatorRequestStatus.rejected => (
              Icons.block,
              QioColors.error,
              l10n.requestRejected,
              l10n.rejectedBody,
            ),
            OperatorRequestStatus.removed => (
              Icons.person_off_outlined,
              QioColors.error,
              l10n.removedTitle,
              l10n.removedBody,
            ),
            null => (
              Icons.help_outline,
              QioColors.gray400,
              l10n.requestNotFound,
              l10n.requestNotFoundBody,
            ),
          };
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              QioCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(icon, size: 56, color: color),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: QioTextStyles.heading2,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: QioTextStyles.body.copyWith(
                        color: QioColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (request?.status == OperatorRequestStatus.approved)
                QioButton(
                  label: l10n.openQueue,
                  isFullWidth: true,
                  onPressed: _openQueue,
                )
              else if (request?.status == OperatorRequestStatus.pending)
                QioButton(
                  label: l10n.cancelRequest,
                  variant: QioButtonVariant.secondary,
                  isFullWidth: true,
                  isLoading: _cancelLoading,
                  onPressed: _cancelLoading ? null : _cancel,
                )
              else
                QioButton(
                  label: l10n.back,
                  variant: QioButtonVariant.secondary,
                  isFullWidth: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
            ],
          );
        },
      ),
    );
  }
}
