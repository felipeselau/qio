import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/queue.dart';
import '../models/queue_entry.dart';
import '../services/entry_diff.dart';
import '../services/group_service.dart';
import '../services/haptics.dart';
import '../services/onboarding_service.dart';
import '../services/operator_service.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/onboarding_tour.dart';
import '../widgets/qio_badge.dart';
import '../widgets/queue_panel/queue_action_bar.dart';
import '../widgets/queue_panel/queue_status_actions.dart';
import '../widgets/queue_panel/status_message_dialog.dart';
import '../widgets/queue_panel/delete_queue_dialog.dart';
import '../widgets/queue_panel/queue_panel_body.dart';
import '../theme/qio_palette.dart';

class QueuePanelScreen extends StatefulWidget {
  const QueuePanelScreen({
    super.key,
    required this.queueId,
    required this.queueName,
    this.isOwner = true,
    this.queues,
    this.operators,
    this.groups,
    this.showTour = true,
  });

  final String queueId;
  final String queueName;
  final bool isOwner;
  final QueueService? queues;
  final OperatorService? operators;
  @visibleForTesting
  final GroupService? groups;
  @visibleForTesting
  final bool showTour;

  @override
  State<QueuePanelScreen> createState() => _QueuePanelScreenState();
}

class _QueuePanelScreenState extends State<QueuePanelScreen> {
  QueueService get _queues => widget.queues ?? QueueService.instance;
  OperatorService get _operators =>
      widget.operators ?? OperatorService.instance;

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
    if (widget.isOwner && widget.showTour) {
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
    _joinSub = _queues
        .watchEntries(widget.queueId)
        .listen(_onEntries, onError: (_) {});
    if (widget.isOwner) {
      _repairMirror();
    } else {
      _accessSub = _operators.watchIsOperator(widget.queueId).listen((
        isOperator,
      ) {
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
      await _queues.ensureMirror(widget.queueId);
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
    return e.isHandledBy(_queues.currentUid, isOwner: widget.isOwner);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: !(_actionLoading || _finishLoading || _deleteLoading),
      child: Scaffold(
        backgroundColor: context.qio.gray100,
        appBar: AppBar(
          backgroundColor: context.qio.surface,
          leading: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '←',
              style: context.qioText.heading3.copyWith(
                color: context.qio.primaryText,
              ),
            ),
          ),
          title: StreamBuilder<Queue>(
            stream: _queues.watchQueue(widget.queueId),
            builder: (context, snap) {
              final q = snap.data;
              final status = q?.status ?? QueueStatus.open;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.queueName,
                      maxLines: 1,
                      style: context.qioText.heading3.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.qio.textPrimary,
                      ),
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
              QueueStatusActions(
                queueId: widget.queueId,
                queueName: widget.queueName,
                onStatus: _updateStatus,
                queues: _queues,
              ),
          ],
        ),
        body: QueuePanelBody(
          queueId: widget.queueId,
          queueName: widget.queueName,
          isOwner: widget.isOwner,
          qrKey: _qrKey,
          isMine: _isMine,
          onServed: _markServed,
          onNoShow: _markNoShow,
          onCall: _callEntry,
          onMoveToEnd: _moveToEnd,
          onRecall: _recall,
          queues: _queues,
          groups: widget.groups,
        ),
        bottomNavigationBar: QueueActionBar(
          queueId: widget.queueId,
          isOwner: widget.isOwner,
          callNextKey: _callNextKey,
          actionLoading: _actionLoading,
          finishLoading: _finishLoading,
          deleteLoading: _deleteLoading,
          isMine: _isMine,
          onCallNext: _callNext,
          onServed: _markServed,
          onNoShow: _markNoShow,
          onDelete: _confirmDelete,
          queues: _queues,
        ),
      ),
    );
  }

  Future<void> _callNext() async {
    setState(() => _actionLoading = true);
    try {
      final next = await _queues.callNext(widget.queueId);
      Haptics.instance.medium();
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

  Future<void> _callEntry(QueueEntry entry) async {
    try {
      final called = await _queues.callEntry(widget.queueId, entry);
      Haptics.instance.medium();
      if (called == null && mounted) {
        _notify(AppLocalizations.of(context).entryUnavailable);
      }
    } on Exception catch (e) {
      _showError(e);
    }
  }

  Future<void> _moveToEnd(QueueEntry entry) async {
    try {
      await _queues.moveEntryToEnd(widget.queueId, entry);
      Haptics.instance.light();
      if (mounted) {
        _notify(AppLocalizations.of(context).movedToEnd(entry.name));
      }
    } on Exception catch (e) {
      _showError(e);
    }
  }

  Future<void> _recall(QueueEntry entry) async {
    try {
      await _queues.recallEntry(widget.queueId, entry);
      Haptics.instance.medium();
      if (mounted) _notify(AppLocalizations.of(context).callResent);
    } on Exception catch (e) {
      _showError(e);
    }
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _updateStatus(QueueStatus status, StatusChange? change) async {
    try {
      await _queues.updateQueueStatus(
        widget.queueId,
        status,
        message: change?.message,
        resumeAt: change?.resumeAt,
      );
    } on Exception catch (e) {
      _showError(e);
    }
  }

  Future<void> _markServed(QueueEntry entry) async {
    setState(() => _finishLoading = true);
    try {
      await _queues.markServed(widget.queueId, entry);
      Haptics.instance.light();
    } on Exception catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _finishLoading = false);
    }
  }

  Future<void> _markNoShow(QueueEntry entry) async {
    setState(() => _finishLoading = true);
    try {
      await _queues.markNoShow(widget.queueId, entry);
      Haptics.instance.heavy();
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

  Future<void> _confirmDelete() async {
    final confirmed = await confirmDeleteQueue(context);
    if (!confirmed || !mounted) return;
    setState(() => _deleteLoading = true);
    try {
      await _queues.deleteQueue(widget.queueId);
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
