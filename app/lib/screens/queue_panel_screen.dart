import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/queue.dart';
import '../models/queue_entry.dart';
import '../services/action_errors.dart';
import '../services/deferred_action.dart';
import '../services/entry_diff.dart';
import '../services/group_service.dart';
import '../services/haptics.dart';
import '../services/operator_service.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../widgets/queue_panel/queue_action_bar.dart';
import '../widgets/queue_panel/panel_notices.dart';
import '../widgets/queue_panel/queue_panel_title.dart';
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
  final _deferred = DeferredActions<String>();
  Set<String> _hidden = const {};
  bool _disposing = false;
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
        showPanelTour(context, _qrKey, _callNextKey);
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
    announceNewEntries(context, entries, added);
  }

  Future<void> _repairMirror() async {
    try {
      await _queues.ensureMirror(widget.queueId);
    } on Exception {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showSyncError(context);
      });
    }
  }

  @override
  void dispose() {
    _disposing = true;
    unawaited(_deferred.flushAll());
    _accessSub?.cancel();
    _joinSub?.cancel();
    super.dispose();
  }

  Future<void> _onAccessLost() async {
    if (_accessLost || !mounted) return;
    _accessLost = true;
    await _accessSub?.cancel();
    if (!mounted) return;
    await showAccessEndedDialog(context);
    if (mounted) Navigator.of(context).pop();
  }

  bool _isMine(QueueEntry e) {
    return e.isHandledBy(_queues.currentUid, isOwner: widget.isOwner);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !(_actionLoading || _finishLoading || _deleteLoading),
      child: Scaffold(
        backgroundColor: context.qio.gray100,
        appBar: AppBar(
          backgroundColor: context.qio.surface,
          leading: const QueueBackButton(),
          title: QueuePanelTitle(
            queueId: widget.queueId,
            queueName: widget.queueName,
            queues: _queues,
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
          hiddenIds: _hidden,
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
          hiddenIds: _hidden,
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
      if (next == null && mounted) showNobodyInQueue(context);
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

  void _markServed(QueueEntry entry) {
    _deferFinish(entry, served: true);
  }

  void _markNoShow(QueueEntry entry) {
    _deferFinish(entry, served: false);
  }

  void _deferFinish(QueueEntry entry, {required bool served}) {
    final scheduled = _deferred.schedule(
      entry.id,
      () => _finish(entry, served: served),
    );
    if (!scheduled) return;
    setState(() => _hidden = _deferred.pendingKeys);
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            served
                ? l10n.finishedServedUndo(entry.name)
                : l10n.finishedNoShowUndo(entry.name),
          ),
          duration: _deferred.delay,
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => _undoFinish(entry.id),
          ),
        ),
      );
  }

  void _undoFinish(String id) {
    if (!_deferred.cancel(id)) return;
    if (mounted) setState(() => _hidden = _deferred.pendingKeys);
  }

  Future<void> _finish(QueueEntry entry, {required bool served}) async {
    if (mounted && !_disposing) {
      setState(() {
        _hidden = {..._deferred.pendingKeys, entry.id};
        _finishLoading = true;
      });
    }
    try {
      if (served) {
        await _queues.markServed(widget.queueId, entry);
        Haptics.instance.light();
      } else {
        await _queues.markNoShow(widget.queueId, entry);
        Haptics.instance.heavy();
      }
    } on Exception catch (e) {
      _showError(e);
    } finally {
      if (mounted && !_disposing) {
        setState(() {
          _hidden = _deferred.pendingKeys;
          _finishLoading = false;
        });
      }
    }
  }

  void _showError(Object e) {
    if (!mounted || _disposing) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            describeActionError(e).message(AppLocalizations.of(context)),
          ),
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
    } on Exception catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _deleteLoading = false);
    }
  }
}
