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
  QueueEntry? _currentCalled;
  bool _actionLoading = false;

  @override
  Widget build(BuildContext context) {
    final joinUrl = QueueService.instance.queueJoinUrl(widget.queueId);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.queueName),
        actions: [
          StreamBuilder<Queue>(
            stream: QueueService.instance.watchQueue(widget.queueId),
            builder: (context, snap) {
              final q = snap.data;
              if (q == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: PopupMenuButton<String>(
                  onSelected: (v) {
                    final status = QueueStatusX.fromValue(v);
                    QueueService.instance.updateQueueStatus(
                      widget.queueId,
                      status,
                    );
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: QueueStatus.open.value,
                      child: Text(QueueStatus.open.label),
                    ),
                    PopupMenuItem(
                      value: QueueStatus.paused.value,
                      child: Text(QueueStatus.paused.label),
                    ),
                    PopupMenuItem(
                      value: QueueStatus.closed.value,
                      child: Text(QueueStatus.closed.label),
                    ),
                  ],
                  child: QioBadge(
                    label: q.status.label,
                    status: switch (q.status) {
                      QueueStatus.open => QioBadgeStatus.open,
                      QueueStatus.paused => QioBadgeStatus.paused,
                      QueueStatus.closed => QioBadgeStatus.closed,
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<QueueEntry>>(
        stream: QueueService.instance.watchEntries(widget.queueId),
        builder: (context, snap) {
          final entries = snap.data ?? [];
          final waiting = entries
              .where((e) => e.status == EntryStatus.waiting)
              .toList();
          final called = entries
              .where((e) => e.status == EntryStatus.called)
              .toList();
          final current = called.isNotEmpty ? called.first : _currentCalled;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              QioCard(
                child: Column(
                  children: [
                    Text(
                      'Escaneie para entrar na fila',
                      style: QioTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 16),
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
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    QioButton(
                      label: 'Compartilhar link',
                      variant: QioButtonVariant.secondary,
                      icon: Icons.share,
                      isFullWidth: true,
                      onPressed: () => _share(context, joinUrl),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _CurrentCalledCard(entry: current, queueId: widget.queueId),
              const SizedBox(height: 16),
              if (waiting.isEmpty)
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
                )
              else
                ...waiting.map((e) => _WaitingTile(entry: e)),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: QioButton(
                  label: 'Chamar próximo',
                  icon: Icons.navigate_next,
                  onPressed: _actionLoading ? null : _callNext,
                  isLoading: _actionLoading,
                  isFullWidth: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _callNext() async {
    setState(() => _actionLoading = true);
    try {
      final next = await QueueService.instance.callNext(widget.queueId);
      if (next != null) {
        setState(() => _currentCalled = next);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ninguém na fila'),
            backgroundColor: QioColors.warning,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  void _share(BuildContext context, String url) {
    // TODO: implement share via share_plus (fase 2)
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Link: $url')));
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
    return QioCard(
      color: QioColors.primary.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Chamando agora', style: QioTextStyles.label),
          const SizedBox(height: 8),
          Row(
            children: [
              QioAvatar(name: e.name, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${e.ticket}',
                      style: QioTextStyles.heading1.copyWith(
                        color: QioColors.primary,
                      ),
                    ),
                    Text(e.name, style: QioTextStyles.bodyMedium),
                    if (e.phone != null)
                      Text(e.phone!, style: QioTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: QioButton(
                  label: 'Atendido',
                  variant: QioButtonVariant.secondary,
                  icon: Icons.check,
                  isFullWidth: true,
                  onPressed: () => QueueService.instance.markServed(queueId, e),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: QioButton(
                  label: 'Não compareceu',
                  variant: QioButtonVariant.danger,
                  icon: Icons.person_off,
                  isFullWidth: true,
                  onPressed: () => QueueService.instance.markNoShow(queueId, e),
                ),
              ),
            ],
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
      child: QioCard(
        child: Row(
          children: [
            QioAvatar(name: entry.name, size: 40),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.name, style: QioTextStyles.bodyMedium),
                  Text(
                    '#${entry.ticket} · há ${waitMin}min',
                    style: QioTextStyles.caption,
                  ),
                ],
              ),
            ),
            const Icon(Icons.access_time, size: 18, color: QioColors.gray400),
          ],
        ),
      ),
    );
  }
}
