import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/operator.dart';
import '../models/queue.dart';
import '../services/operator_service.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/qio_avatar.dart';
import '../widgets/qio_button.dart';
import '../widgets/qio_card.dart';

class OperatorsScreen extends StatefulWidget {
  const OperatorsScreen({super.key, required this.queueId});

  final String queueId;

  @override
  State<OperatorsScreen> createState() => _OperatorsScreenState();
}

class _OperatorsScreenState extends State<OperatorsScreen> {
  static const _validityOptions = <String, Duration?>{
    '1 hora': Duration(hours: 1),
    '24 horas': OperatorService.defaultInviteValidity,
    '7 dias': Duration(days: 7),
    'Sem expiração': null,
  };

  late final Stream<Queue> _queueStream;
  late final Stream<List<OperatorRequest>> _requestsStream;
  late final Stream<List<QueueOperator>> _operatorsStream;
  String _validity = '24 horas';
  bool _inviteLoading = false;
  final Set<String> _busyUids = {};

  @override
  void initState() {
    super.initState();
    _queueStream = QueueService.instance.watchQueue(widget.queueId);
    _requestsStream = OperatorService.instance.watchOperatorRequests(
      widget.queueId,
    );
    _operatorsStream = OperatorService.instance.watchOperators(widget.queueId);
    OperatorService.instance.syncOperatorMirror(widget.queueId).ignore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QioColors.gray100,
      appBar: AppBar(
        backgroundColor: QioColors.surface,
        title: Text(
          'Operadores',
          style: QioTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: QioColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder<Queue>(
            stream: _queueStream,
            builder: (context, snap) => _buildInviteCard(snap.data),
          ),
          const SizedBox(height: 24),
          _sectionTitle('PEDIDOS PENDENTES'),
          const SizedBox(height: 12),
          StreamBuilder<List<OperatorRequest>>(
            stream: _requestsStream,
            builder: (context, snap) {
              final requests = snap.data ?? [];
              if (requests.isEmpty) {
                return _emptyCard('Nenhum pedido pendente');
              }
              return Column(children: requests.map(_buildRequestTile).toList());
            },
          ),
          const SizedBox(height: 24),
          _sectionTitle('OPERADORES ATIVOS'),
          const SizedBox(height: 12),
          StreamBuilder<List<QueueOperator>>(
            stream: _operatorsStream,
            builder: (context, snap) {
              final operators = snap.data ?? [];
              if (operators.isEmpty) {
                return _emptyCard('Nenhum operador ainda');
              }
              return Column(
                children: operators.map(_buildOperatorTile).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: QioTextStyles.label.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: QioColors.gray700,
      ),
    );
  }

  Widget _emptyCard(String text) {
    return QioCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(child: Text(text, style: QioTextStyles.caption)),
      ),
    );
  }

  Widget _buildInviteCard(Queue? queue) {
    final code = queue?.operatorInviteCode;
    final expiresAt = queue?.operatorInviteExpiresAt;
    final expired = isInviteExpired(expiresAt, DateTime.now());
    final active = code != null && !expired;

    return QioCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Código de convite',
            style: QioTextStyles.heading3.copyWith(
              fontWeight: FontWeight.w600,
              color: QioColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Quem receber o código pede acesso pelo app. Você aprova cada pedido.',
            style: QioTextStyles.caption,
          ),
          const SizedBox(height: 16),
          if (active) ...[
            SelectableText(
              code,
              textAlign: TextAlign.center,
              style: QioTextStyles.ticket.copyWith(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
                color: QioColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              expiresAt == null
                  ? 'Sem expiração'
                  : 'Válido até ${_formatDateTime(expiresAt)}',
              textAlign: TextAlign.center,
              style: QioTextStyles.caption,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: QioButton(
                    label: 'Copiar',
                    icon: Icons.copy,
                    fontSize: 14,
                    isFullWidth: true,
                    onPressed: () => _copyCode(code),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QioButton(
                    label: 'Compartilhar',
                    icon: Icons.share_outlined,
                    variant: QioButtonVariant.secondary,
                    fontSize: 14,
                    isFullWidth: true,
                    onPressed: () => _shareCode(code, queue?.name ?? ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            QioButton(
              label: 'Revogar código',
              variant: QioButtonVariant.dangerSoft,
              fontSize: 14,
              isFullWidth: true,
              isLoading: _inviteLoading,
              onPressed: _inviteLoading ? null : _revoke,
            ),
          ] else ...[
            if (expired)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'O código anterior expirou.',
                  style: QioTextStyles.caption.copyWith(
                    color: QioColors.warning,
                  ),
                ),
              ),
            Text('Validade', style: QioTextStyles.label),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _validityOptions.keys
                  .map(
                    (label) => ChoiceChip(
                      label: Text(label),
                      selected: _validity == label,
                      onSelected: (_) => setState(() => _validity = label),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          QioButton(
            label: active ? 'Gerar novo código' : 'Gerar código',
            variant: active
                ? QioButtonVariant.secondary
                : QioButtonVariant.primary,
            icon: Icons.vpn_key_outlined,
            fontSize: 14,
            isFullWidth: true,
            isLoading: _inviteLoading && !active,
            onPressed: _inviteLoading ? null : _generate,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTile(OperatorRequest request) {
    final busy = _busyUids.contains(request.uid);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: QioCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _personRow(request.label, request.email),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: QioButton(
                    label: 'Recusar',
                    variant: QioButtonVariant.dangerSoft,
                    fontSize: 14,
                    isFullWidth: true,
                    onPressed: busy ? null : () => _reject(request),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QioButton(
                    label: 'Aprovar',
                    variant: QioButtonVariant.successSoft,
                    fontSize: 14,
                    isFullWidth: true,
                    isLoading: busy,
                    onPressed: busy ? null : () => _approve(request),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorTile(QueueOperator operator) {
    final busy = _busyUids.contains(operator.uid);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: QioCard(
        child: Row(
          children: [
            Expanded(child: _personRow(operator.label, operator.email)),
            IconButton(
              tooltip: 'Remover operador',
              icon: const Icon(Icons.person_remove_outlined),
              color: QioColors.error,
              onPressed: busy ? null : () => _confirmRemove(operator),
            ),
          ],
        ),
      ),
    );
  }

  Widget _personRow(String label, String? email) {
    return Row(
      children: [
        QioAvatar(name: label, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: QioTextStyles.bodyMedium.copyWith(
                  fontSize: 14,
                  color: QioColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              if (email != null && email != label)
                Text(
                  email,
                  style: QioTextStyles.caption.copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }

  Future<void> _generate() async {
    setState(() => _inviteLoading = true);
    try {
      await OperatorService.instance.generateOperatorInvite(
        widget.queueId,
        validFor: _validityOptions[_validity],
      );
    } on Exception catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _inviteLoading = false);
    }
  }

  Future<void> _revoke() async {
    setState(() => _inviteLoading = true);
    try {
      await OperatorService.instance.revokeOperatorInvite(widget.queueId);
    } on Exception catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _inviteLoading = false);
    }
  }

  Future<void> _approve(OperatorRequest request) async {
    await _runForUid(
      request.uid,
      () => OperatorService.instance.approveOperatorRequest(
        widget.queueId,
        request,
      ),
    );
  }

  Future<void> _reject(OperatorRequest request) async {
    await _runForUid(
      request.uid,
      () => OperatorService.instance.rejectOperatorRequest(
        widget.queueId,
        request.uid,
      ),
    );
  }

  Future<void> _confirmRemove(QueueOperator operator) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover operador?'),
        content: Text(
          '${operator.label} perde o acesso à fila. Atendimentos já chamados por essa pessoa continuam na fila.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Remover',
              style: TextStyle(color: QioColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runForUid(
      operator.uid,
      () =>
          OperatorService.instance.removeOperator(widget.queueId, operator.uid),
    );
  }

  Future<void> _runForUid(String uid, Future<void> Function() action) async {
    setState(() => _busyUids.add(uid));
    try {
      await action();
    } on Exception catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busyUids.remove(uid));
    }
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código copiado!'),
        backgroundColor: QioColors.secondary,
      ),
    );
  }

  Future<void> _shareCode(String code, String queueName) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          text:
              'Código para atender a fila "$queueName" no Qio: $code\n'
              'Abra o app Qio > Entrar como operador.',
        ),
      );
    } on Exception catch (e) {
      _showError(e);
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e is OperatorInviteException
              ? e.message
              : 'Não foi possível concluir a ação. Tente novamente.',
        ),
        backgroundColor: QioColors.error,
      ),
    );
  }
}
