import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/queue.dart';
import '../models/queue_entry.dart';
import '../services/entry_diff.dart';
import '../services/onboarding_service.dart';
import '../services/operator_service.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/onboarding_tour.dart';
import '../widgets/qio_avatar.dart';
import '../widgets/qio_badge.dart';
import '../widgets/qio_button.dart';
import '../widgets/qio_card.dart';
import 'history_screen.dart';
import 'operators_screen.dart';
import 'qr_poster_screen.dart';

class QueuePanelScreen extends StatefulWidget {
  const QueuePanelScreen({
    super.key,
    required this.queueId,
    required this.queueName,
    this.isOwner = true,
  });

  final String queueId;
  final String queueName;
  final bool isOwner;

  @override
  State<QueuePanelScreen> createState() => _QueuePanelScreenState();
}

class _QueuePanelScreenState extends State<QueuePanelScreen> {
  bool _actionLoading = false;
  bool _finishLoading = false;
  bool _deleteLoading = false;
  StreamSubscription<bool>? _accessSub;
  bool _accessLost = false;
  StreamSubscription<List<QueueEntry>>? _joinSub;
  Set<String>? _lastWaiting;
  final _qrKey = GlobalKey();
  final _callNextKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.isOwner) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        final l10n = AppLocalizations.of(context);
        showOnboardingTour(context, OnboardingTour.panel, [
          OnboardingStep(
            key: _qrKey,
            title: l10n.tourPanelQrTitle,
            body: l10n.tourPanelQrBody,
          ),
          OnboardingStep(
            key: _callNextKey,
            title: l10n.tourPanelCallTitle,
            body: l10n.tourPanelCallBody,
            above: true,
          ),
        ]);
      });
    }
    _joinSub = QueueService.instance
        .watchEntries(widget.queueId)
        .listen(_onEntries, onError: (_) {});
    if (widget.isOwner) {
      _repairMirror();
    } else {
      _accessSub = OperatorService.instance
          .watchIsOperator(widget.queueId)
          .listen((isOperator) {
            if (!isOperator) _onAccessLost();
          });
    }
  }

  void _onEntries(List<QueueEntry> entries) {
    final added = newWaitingIds(_lastWaiting, entries);
    _lastWaiting = waitingIdsOf(entries);
    if (added.isEmpty || !mounted) return;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.alert);
    final l10n = AppLocalizations.of(context);
    final message = added.length == 1
        ? l10n.newPersonInQueue(
            entries.firstWhere((e) => e.id == added.first).name,
          )
        : l10n.newPeopleInQueue(added.length);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
  }

  Future<void> _repairMirror() async {
    try {
      await QueueService.instance.ensureMirror(widget.queueId);
    } on Exception {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).syncError),
            backgroundColor: QioColors.error,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _accessSub?.cancel();
    _joinSub?.cancel();
    super.dispose();
  }

  Future<void> _onAccessLost() async {
    if (_accessLost || !mounted) return;
    _accessLost = true;
    await _accessSub?.cancel();
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.accessEndedTitle),
        content: Text(l10n.accessEndedBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  bool _isMine(QueueEntry e) {
    return e.isHandledBy(
      QueueService.instance.currentUid,
      isOwner: widget.isOwner,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                  label: status.label(l10n),
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
          if (widget.isOwner)
            IconButton(
              icon: Icon(Icons.history, color: QioColors.gray700),
              tooltip: l10n.historyTitle,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => HistoryScreen(
                    queueId: widget.queueId,
                    queueName: widget.queueName,
                  ),
                ),
              ),
            ),
          if (widget.isOwner)
            StreamBuilder<Queue>(
              stream: QueueService.instance.watchQueue(widget.queueId),
              builder: (context, snap) {
                final q = snap.data;
                final status = q?.status ?? QueueStatus.open;
                if (status == QueueStatus.closed) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _StatusButton(
                      label: l10n.reopen,
                      color: QioColors.primary,
                      onPressed: () => _updateStatus(QueueStatus.open),
                    ),
                  );
                }
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _StatusButton(
                      label: status == QueueStatus.paused
                          ? l10n.reopen
                          : l10n.pause,
                      color: QioColors.warning,
                      onPressed: () => _updateStatus(
                        status == QueueStatus.paused
                            ? QueueStatus.open
                            : QueueStatus.paused,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusButton(
                      label: l10n.close,
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
                _buildQrCard(joinUrl),
                const SizedBox(height: 16),
                if (widget.isOwner) ...[
                  _buildOperatorsTile(),
                  const SizedBox(height: 16),
                ],
                QioCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Text(
                          l10n.queueClosedTitle,
                          style: QioTextStyles.heading3.copyWith(
                            fontWeight: FontWeight.w600,
                            color: QioColors.gray700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.noServiceInProgress,
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
                    widget.isOwner
                        ? l10n.closedOwnerHint
                        : l10n.closedOperatorHint,
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
              final mine = called.where(_isMine).toList();
              final others = called.where((e) => !_isMine(e)).toList();
              final current = mine.isNotEmpty ? mine.first : null;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildQrCard(joinUrl),
                  const SizedBox(height: 16),
                  if (widget.isOwner) ...[
                    _buildOperatorsTile(),
                    const SizedBox(height: 16),
                  ],
                  _CurrentCalledCard(entry: current, queueId: widget.queueId),
                  const SizedBox(height: 16),
                  if (others.isNotEmpty) ...[
                    Text(
                      l10n.servingByOthers,
                      style: QioTextStyles.label.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: QioColors.gray700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...others.map(
                      (e) => _WaitingTile(
                        entry: e,
                        trailing: widget.isOwner
                            ? PopupMenuButton<EntryStatus>(
                                tooltip: l10n.finishService,
                                onSelected: (result) =>
                                    result == EntryStatus.served
                                    ? _markServed(e)
                                    : _markNoShow(e),
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: EntryStatus.served,
                                    child: Text(l10n.served),
                                  ),
                                  PopupMenuItem(
                                    value: EntryStatus.noShow,
                                    child: Text(l10n.noShow),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (waiting.isNotEmpty) ...[
                    Text(
                      l10n.upNext,
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
                              l10n.nobodyInQueue,
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
                  if (!widget.isOwner) return const SizedBox.shrink();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      QioButton(
                        label: l10n.deleteQueue,
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
                    final mine = entries
                        .where(
                          (e) => e.status == EntryStatus.called && _isMine(e),
                        )
                        .toList();
                    final current = mine.isNotEmpty ? mine.first : null;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        QioButton(
                          key: _callNextKey,
                          label: l10n.callNext,
                          onPressed: (_actionLoading || current != null)
                              ? null
                              : _callNext,
                          isLoading: _actionLoading,
                          isFullWidth: true,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: QioButton(
                                label: l10n.served,
                                variant: QioButtonVariant.successSoft,
                                isFullWidth: true,
                                fontSize: 14,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                onPressed: current == null || _finishLoading
                                    ? null
                                    : () => _markServed(current),
                                isLoading: _finishLoading,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: QioButton(
                                label: l10n.noShow,
                                variant: QioButtonVariant.dangerSoft,
                                isFullWidth: true,
                                fontSize: 14,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                onPressed: current == null || _finishLoading
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
          SnackBar(
            content: Text(AppLocalizations.of(context).nobodyInQueue),
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
      SnackBar(
        content: Text(AppLocalizations.of(context).genericActionError),
        backgroundColor: QioColors.error,
      ),
    );
  }

  Widget _buildOperatorsTile() {
    final l10n = AppLocalizations.of(context);
    return QioCard(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OperatorsScreen(queueId: widget.queueId),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_outlined, color: QioColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.operatorsAndInvites,
              style: QioTextStyles.bodyMedium.copyWith(
                color: QioColors.textPrimary,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: QioColors.gray400),
        ],
      ),
    );
  }

  Widget _buildQrCard(String joinUrl) {
    final l10n = AppLocalizations.of(context);
    return QioCard(
      key: _qrKey,
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
            child: Semantics(
              image: true,
              label: l10n.qrSemantics,
              child: QrImageView(
                data: joinUrl,
                version: QrVersions.auto,
                size: 180,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.scanToJoin,
            style: QioTextStyles.body.copyWith(
              fontSize: 14,
              color: QioColors.gray700,
            ),
          ),
          const SizedBox(height: 16),
          Semantics(
            button: true,
            label: l10n.copyLinkSemantics,
            child: GestureDetector(
              onTap: () => _copyLink(joinUrl),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: QioColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        joinUrl.replaceFirst('https://', ''),
                        style: QioTextStyles.caption.copyWith(
                          fontSize: 13,
                          color: QioColors.gray700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.copy, size: 16, color: QioColors.primary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: QioButton(
                  label: l10n.copyLink,
                  icon: Icons.copy,
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  isFullWidth: true,
                  onPressed: () => _copyLink(joinUrl),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: QioButton(
                  label: l10n.share,
                  variant: QioButtonVariant.secondary,
                  icon: Icons.share_outlined,
                  fontSize: 14,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  isFullWidth: true,
                  onPressed: () => _share(joinUrl),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          QioButton(
            label: l10n.printablePoster,
            variant: QioButtonVariant.ghost,
            icon: Icons.print,
            fontSize: 14,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            isFullWidth: true,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => QrPosterScreen(
                  queueName: widget.queueName,
                  joinUrl: joinUrl,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _copyLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).linkCopied),
        backgroundColor: QioColors.secondary,
      ),
    );
  }

  Future<void> _share(String url) async {
    try {
      await SharePlus.instance.share(ShareParams(text: url));
    } on Exception catch (e) {
      _showError(e);
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
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
              l10n.deleteQueueTitle,
              style: QioTextStyles.heading2.copyWith(
                fontWeight: FontWeight.w700,
                color: QioColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.deleteQueueBody,
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
                    label: l10n.cancel,
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
                    label: l10n.delete,
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
    final l10n = AppLocalizations.of(context);
    if (entry == null) {
      return QioCard(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            children: [
              Icon(Icons.person_search, size: 40, color: QioColors.gray300),
              const SizedBox(height: 12),
              Text(l10n.nobodyCalled, style: QioTextStyles.bodyMedium),
              const SizedBox(height: 4),
              Text(l10n.callNextHint, style: QioTextStyles.caption),
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
            l10n.callingNow,
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
  const _WaitingTile({required this.entry, this.trailing});

  final QueueEntry entry;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                    l10n.waitTileSubtitle(entry.ticket, waitMin),
                    style: QioTextStyles.caption.copyWith(
                      fontSize: 12,
                      color: QioColors.gray400,
                    ),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
