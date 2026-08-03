import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/queue.dart';
import '../models/queue_entry.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/qio_avatar.dart';
import '../widgets/qio_badge.dart';
import '../widgets/qio_button.dart';
import '../widgets/qio_card.dart';

class QueuePanelScreen extends StatefulWidget {
  const QueuePanelScreen({
    super.key,
    required this.queueId,
    required this.queueName,
  });

  final String queueId;
  final String queueName;

  @override
  State<QueuePanelScreen> createState() => _QueuePanelScreenState();
}

class _QueuePanelScreenState extends State<QueuePanelScreen> {
  bool _actionLoading = false;
  bool _finishLoading = false;
  bool _deleteLoading = false;

  @override
  Widget build(BuildContext context) {
    final joinUrl = QueueService.instance.queueJoinUrl(widget.queueId);
    return Scaffold(
      backgroundColor: QioColors.gray100,
      appBar: AppBar(
        backgroundColor: QioColors.surface,
        leading: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            '←',
            style: QioTextStyles.heading3.copyWith(color: QioColors.primary),
          ),
        ),
        title: StreamBuilder<Queue>(
          stream: QueueService.instance.watchQueue(widget.queueId),
          builder: (context, snap) {
            final q = snap.data;
            final status = q?.status ?? QueueStatus.open;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.queueName,
                  style: QioTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w700,
                    color: QioColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                QioBadge(
                  label: status.label,
                  status: switch (status) {
                    QueueStatus.open => QioBadgeStatus.open,
                    QueueStatus.paused => QioBadgeStatus.paused,
                    QueueStatus.closed => QioBadgeStatus.closed,
                  },
                ),
              ],
            );
          },
        ),
        centerTitle: true,
        actions: [
          StreamBuilder<Queue>(
            stream: QueueService.instance.watchQueue(widget.queueId),
            builder: (context, snap) {
              final q = snap.data;
              final status = q?.status ?? QueueStatus.open;
              if (status == QueueStatus.closed) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _StatusButton(
                    label: 'Reabrir',
                    color: QioColors.primary,
                    onPressed: () => _updateStatus(QueueStatus.open),
                  ),
                );
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _StatusButton(
                    label: status == QueueStatus.paused ? 'Reabrir' : 'Pausar',
                    color: QioColors.warning,
                    onPressed: () => _updateStatus(
                      status == QueueStatus.paused
                          ? QueueStatus.open
                          : QueueStatus.paused,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusButton(
                    label: 'Fechar',
                    color: QioColors.error,
                    onPressed: () => _updateStatus(QueueStatus.closed),
                  ),
                  const SizedBox(width: 12),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<Queue>(
        stream: QueueService.instance.watchQueue(widget.queueId),
        builder: (context, queueSnap) {
          final status = queueSnap.data?.status ?? QueueStatus.open;
          if (status == QueueStatus.closed) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                QioCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: QioColors.gray200),
                        ),
                        child: QrImageView(
                          data: joinUrl,
                          version: QrVersions.auto,
                          size: 180,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Escaneie para entrar na fila',
                        style: QioTextStyles.body.copyWith(
                          fontSize: 14,
                          color: QioColors.gray700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      QioButton(
                        label: 'Compartilhar',
                        variant: QioButtonVariant.secondary,
                        isFullWidth: true,
                        onPressed: () => _share(context, joinUrl),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                QioCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Text(
                          'Fila fechada',
                          style: QioTextStyles.heading3.copyWith(
                            fontWeight: FontWeight.w600,
                            color: QioColors.gray700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Nenhum atendimento em andamento',
                          style: QioTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'A fila está fechada. Você pode reabri-la ou excluí-la.',
                    style: QioTextStyles.body.copyWith(
                      fontSize: 14,
                      color: QioColors.gray400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );
          }
          return StreamBuilder<List<QueueEntry>>(
            stream: QueueService.instance.watchEntries(widget.queueId),
            builder: (context, snap) {
              final entries = snap.data ?? [];
              final waiting = entries
                  .where((e) => e.status == EntryStatus.waiting)
                  .toList();
              final called = entries
                  .where((e) => e.status == EntryStatus.called)
                  .toList();
              final current = called.isNotEmpty ? called.first : null;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  QioCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: QioColors.gray200),
                          ),
                          child: QrImageView(
                            data: joinUrl,
                            version: QrVersions.auto,
                            size: 180,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Escaneie para entrar na fila',
                          style: QioTextStyles.body.copyWith(
                            fontSize: 14,
                            color: QioColors.gray700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        QioButton(
                          label: 'Compartilhar',
                          variant: QioButtonVariant.secondary,
                          isFullWidth: true,
                          onPressed: () => _share(context, joinUrl),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _CurrentCalledCard(entry: current, queueId: widget.queueId),
                  const SizedBox(height: 16),
                  if (waiting.isNotEmpty) ...[
                    Text(
                      'PRÓXIMOS NA FILA',
                      style: QioTextStyles.label.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: QioColors.gray700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...waiting.map((e) => _WaitingTile(entry: e)),
                  ] else
                    QioCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.hourglass_empty,
                              size: 40,
                              color: QioColors.gray300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Ninguém na fila',
                              style: QioTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: QioColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              offset: const Offset(0, -2),
              blurRadius: 8,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<Queue>(
              stream: QueueService.instance.watchQueue(widget.queueId),
              builder: (context, qSnap) {
                final status = qSnap.data?.status ?? QueueStatus.open;
                if (status == QueueStatus.closed) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QioButton(
                        label: 'Excluir fila',
                        variant: QioButtonVariant.danger,
                        icon: Icons.delete_outline,
                        isFullWidth: true,
                        onPressed: _deleteLoading ? null : _confirmDelete,
                        isLoading: _deleteLoading,
                      ),
                    ],
                  );
                }
                return StreamBuilder<List<QueueEntry>>(
                  stream: QueueService.instance.watchEntries(widget.queueId),
                  builder: (context, snap) {
                    final entries = snap.data ?? [];
                    final called = entries
                        .where((e) => e.status == EntryStatus.called)
                        .toList();
                    final current = called.isNotEmpty ? called.first : null;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        QioButton(
                          label: 'Chamar próximo',
                          onPressed: _actionLoading ? null : _callNext,
                          isLoading: _actionLoading,
                          isFullWidth: true,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: QioButton(
                                label: 'Atendido',
                                variant: QioButtonVariant.successSoft,
                                isFullWidth: true,
                                fontSize: 14,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                onPressed:
                                    current == null || _finishLoading
                                    ? null
                                    : () => _markServed(current),
                                isLoading: _finishLoading,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: QioButton(
                                label: 'Não compareceu',
                                variant: QioButtonVariant.dangerSoft,
                                isFullWidth: true,
                                fontSize: 14,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                onPressed:
                                    current == null || _finishLoading
                                    ? null
                                    : () => _markNoShow(current),
                                isLoading: _finishLoading,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _callNext() async {
    setState(() => _actionLoading = true);
    try {
      final next = await QueueService.instance.callNext(widget.queueId);
      if (next == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ninguém na fila'),
            backgroundColor: QioColors.warning,
          ),
        );
      }
    } on Exception catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _updateStatus(QueueStatus status) async {
    try {
      await QueueService.instance.updateQueueStatus(widget.queueId, status);
    } on Exception catch (e) {
      _showError(e);
    }
  }

  Future<void> _markServed(QueueEntry entry) async {
    setState(() => _finishLoading = true);
    try {
      await QueueService.instance.markServed(widget.queueId, entry);
    } on Exception catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _finishLoading = false);
    }
  }

  Future<void> _markNoShow(QueueEntry entry) async {
    setState(() => _finishLoading = true);
    try {
      await QueueService.instance.markNoShow(widget.queueId, entry);
    } on Exception catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _finishLoading = false);
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Não foi possível concluir a ação. Tente novamente.'),
        backgroundColor: QioColors.error,
      ),
    );
  }

  void _share(BuildContext context, String url) {
    // TODO: implement share via share_plus (fase 2)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Link: $url')));
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: QioColors.error.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline,
                color: QioColors.error,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Excluir fila?',
              style: QioTextStyles.heading2.copyWith(
                fontWeight: FontWeight.w700,
                color: QioColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Essa ação é permanente. A fila e todo o histórico de atendimentos serão apagados.',
              style: QioTextStyles.body.copyWith(
                fontSize: 14,
                color: QioColors.gray500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: QioButton(
                    label: 'Cancelar',
                    variant: QioButtonVariant.secondary,
                    isFullWidth: true,
                    fontSize: 14,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: QioButton(
                    label: 'Excluir',
                    variant: QioButtonVariant.danger,
                    isFullWidth: true,
                    fontSize: 14,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleteLoading = true);
    try {
      await QueueService.instance.deleteQueue(widget.queueId);
      if (mounted) Navigator.of(context).pop();
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: QioColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deleteLoading = false);
    }
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color),
        ),
        child: Text(
          label,
          style: QioTextStyles.caption.copyWith(fontSize: 12, color: color),
        ),
      ),
    );
  }
}

class _CurrentCalledCard extends StatelessWidget {
  const _CurrentCalledCard({this.entry, required this.queueId});

  final QueueEntry? entry;
  final String queueId;

  @override
  Widget build(BuildContext context) {
    if (entry == null) {
      return QioCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(Icons.person_search, size: 40, color: QioColors.gray300),
              const SizedBox(height: 12),
              Text('Ninguém chamado', style: QioTextStyles.bodyMedium),
              const SizedBox(height: 4),
              Text(
                'Toque "Chamar próximo" para começar',
                style: QioTextStyles.caption,
              ),
            ],
          ),
        ),
      );
    }
    final e = entry!;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: QioColors.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: QioColors.primary.withValues(alpha: 0.25),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'CHAMANDO AGORA',
            style: QioTextStyles.label.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.6),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '#${e.ticket}',
            style: QioTextStyles.ticket.copyWith(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            e.name,
            style: QioTextStyles.heading3.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingTile extends StatelessWidget {
  const _WaitingTile({required this.entry});

  final QueueEntry entry;

  @override
  Widget build(BuildContext context) {
    final waitMin = DateTime.now().difference(entry.joinedAt).inMinutes;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: QioColors.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              offset: const Offset(0, 1),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            QioAvatar(name: entry.name, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: QioTextStyles.bodyMedium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: QioColors.textPrimary,
                    ),
                  ),
                  Text(
                    '#${entry.ticket} · $waitMin min',
                    style: QioTextStyles.caption.copyWith(
                      fontSize: 12,
                      color: QioColors.gray400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
