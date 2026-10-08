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
import '../widgets/queue_panel/queue_settings_actions.dart';
import '../widgets/queue_panel/queue_settings_sections.dart';
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

const _finishTimeout = Duration(seconds: 10);

class _QueuePanelScreenState extends State<QueuePanelScreen>
    with WidgetsBindingObserver {
  QueueService get _queues => widget.queues ?? QueueService.instance;
  OperatorService get _operators =>
      widget.operators ?? OperatorService.instance;

  bool _actionLoading = false;
  int _finishCount = 0;
  bool get _finishLoading => _finishCount > 0;
  bool _deleteLoading = false;
  late final _deferred = DeferredActions<String>(onError: _reportError);
  final Set<String> _finishing = {};
  Set<String> _hidden = const {};
  bool _disposing = false;
  ScaffoldMessengerState? _messenger;
  AppLocalizations? _l10n;
  StreamSubscription<bool>? _accessSub;
  bool _accessLost = false;
  StreamSubscription<List<QueueEntry>>? _joinSub;
  Set<String>? _lastWaiting;
  final _qrKey = GlobalKey();
  final _settingsKey = GlobalKey();
  final _callNextKey = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.of(context);
    _l10n = AppLocalizations.of(context);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    const flushing = {
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.detached,
    };
    if (!flushing.contains(state)) return;
    unawaited(_deferred.flushAll());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.isOwner && widget.showTour) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        showPanelTour(context, _qrKey, _settingsKey, _callNextKey);
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
    WidgetsBinding.instance.removeObserver(this);
    _disposing = true;
    _hideSnackBar();
    unawaited(_deferred.flushAll());
    _accessSub?.cancel();
    _joinSub?.cancel();
    super.dispose();
  }

  Future<void> _onAccessLost() async {
    if (_accessLost || !mounted) return;
    _accessLost = true;
    _discardPending();
    await _accessSub?.cancel();
    if (!mounted) return;
    final route = ModalRoute.of(context);
    Navigator.of(context).popUntil((r) => r == route || r.isFirst);
    await showAccessEndedDialog(context);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _onQueueGone() async {
    if (!mounted) return;
    _discardPending();
    await showQueueGoneDialog(context);
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
            if (!isPanelWide(MediaQuery.sizeOf(context).width))
              QueueSettingsActions(
                queueId: widget.queueId,
                queueName: widget.queueName,
                isOwner: widget.isOwner,
                qrKey: _qrKey,
                settingsKey: _settingsKey,
                queues: _queues,
                groups: widget.groups,
                onQueueGone: _onQueueGone,
              ),
            if (widget.isOwner)
              QueueStatusActions(
                queueId: widget.queueId,
                queueName: widget.queueName,
                onStatus: _updateStatus,
                queues: _queues,
                compact: isPanelCompactBar(context),
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

  void _discardPending() {
    _deferred.cancelAll();
    _hideSnackBar();
    if (mounted && !_disposing) _syncHidden();
  }

  void _hideSnackBar() {
    final messenger = _messenger;
    if (messenger != null && messenger.mounted) {
      messenger.hideCurrentSnackBar();
    }
  }

  void _syncHidden() {
    setState(() => _hidden = {..._deferred.pendingKeys, ..._finishing});
  }

  Future<void> _callNext() async {
    await _deferred.flushAll();
    if (!mounted) return;
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
    await _deferred.flushAll();
    if (!mounted) return;
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
    if (_deferred.isPending(entry.id) || _finishing.contains(entry.id)) return;
    if (_deferred.hasPending) unawaited(_deferred.flushAll());
    final delay = MediaQuery.accessibleNavigationOf(context)
        ? _deferred.delay * 2
        : _deferred.delay;
    final scheduled = _deferred.schedule(entry.id, () {
      _hideSnackBar();
      return _finish(entry, served: served);
    }, delay: delay);
    if (!scheduled) return;
    _syncHidden();
    final l10n = AppLocalizations.of(context);
    _messenger!
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            served
                ? l10n.finishedServedUndo(entry.name)
                : l10n.finishedNoShowUndo(entry.name),
          ),
          duration: delay,
          persist: false,
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => _undoFinish(entry.id),
          ),
        ),
      );
  }

  void _undoFinish(String id) {
    if (!_deferred.cancel(id)) return;
    if (mounted && !_disposing) _syncHidden();
  }

  Future<void> _finish(QueueEntry entry, {required bool served}) async {
    _finishing.add(entry.id);
    _finishCount++;
    if (mounted && !_disposing) _syncHidden();
    try {
      if (served) {
        await _queues.markServed(widget.queueId, entry).timeout(_finishTimeout);
        Haptics.instance.light();
      } else {
        await _queues.markNoShow(widget.queueId, entry).timeout(_finishTimeout);
        Haptics.instance.heavy();
      }
    } catch (e, st) {
      _reportError(e, st);
    } finally {
      _finishing.remove(entry.id);
      _finishCount--;
      if (mounted && !_disposing) _syncHidden();
    }
  }

  void _reportError(Object e, StackTrace st) {
    debugPrint('queue panel action failed: $e\n$st');
    _showError(e);
  }

  void _showError(Object e) {
    final messenger = _messenger;
    final l10n = _l10n;
    if (messenger == null || l10n == null) return;
    try {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(describeActionError(e).message(l10n)),
            backgroundColor: QioColors.error,
          ),
        );
    } catch (_) {}
  }

  Future<void> _confirmDelete() async {
    final confirmed = await confirmDeleteQueue(context);
    if (!confirmed || !mounted) return;
    _discardPending();
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
