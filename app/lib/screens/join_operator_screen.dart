import 'package:flutter/material.dart';

import '../models/operator.dart';
import '../services/operator_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/qio_button.dart';
import '../widgets/qio_card.dart';
import '../widgets/qio_input.dart';
import 'queue_panel_screen.dart';

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
                  ? e.message
                  : 'Não foi possível enviar o pedido. Tente novamente.',
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: QioColors.surface,
        title: Text(
          'Entrar como operador',
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
                  'Peça o código de convite ao dono da fila. Depois de enviar, o dono precisa aprovar seu acesso.',
                  style: QioTextStyles.body.copyWith(
                    color: QioColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                QioInput(
                  label: 'Código de convite',
                  hint: 'Ex: K7M2QX',
                  controller: _codeCtrl,
                  prefixIcon: Icons.vpn_key_outlined,
                  validator: (v) =>
                      OperatorService.normalizeCode(v ?? '').length != 6
                      ? 'O código tem 6 caracteres'
                      : null,
                ),
                const SizedBox(height: 32),
                QioButton(
                  label: 'Enviar pedido',
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
          const SnackBar(
            content: Text('Não foi possível cancelar. Tente novamente.'),
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
            return const Center(child: CircularProgressIndicator());
          }
          final request = snap.data;
          final (icon, color, title, subtitle) = switch (request?.status) {
            OperatorRequestStatus.pending => (
              Icons.hourglass_top,
              QioColors.warning,
              'Aguardando aprovação',
              'O dono da fila precisa aprovar seu pedido. Esta tela atualiza sozinha.',
            ),
            OperatorRequestStatus.approved => (
              Icons.check_circle_outline,
              QioColors.success,
              'Pedido aprovado',
              'Você já pode atender esta fila.',
            ),
            OperatorRequestStatus.rejected => (
              Icons.block,
              QioColors.error,
              'Pedido recusado',
              'O dono da fila recusou seu pedido.',
            ),
            null => (
              Icons.help_outline,
              QioColors.gray400,
              'Pedido não encontrado',
              'O pedido foi cancelado ou removido.',
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
                  label: 'Abrir fila',
                  isFullWidth: true,
                  onPressed: _openQueue,
                )
              else if (request?.status == OperatorRequestStatus.pending)
                QioButton(
                  label: 'Cancelar pedido',
                  variant: QioButtonVariant.secondary,
                  isFullWidth: true,
                  isLoading: _cancelLoading,
                  onPressed: _cancelLoading ? null : _cancel,
                )
              else
                QioButton(
                  label: 'Voltar',
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
