import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../controllers/home_controller.dart';
import '../models/operator.dart';
import '../models/queue.dart';
import '../services/action_errors.dart';
import '../services/auth_service.dart';
import '../services/deep_link.dart';
import '../services/home_prompts.dart';
import '../services/push_service.dart';
import '../services/queue_sort.dart';
import '../services/onboarding_service.dart';
import '../services/operator_service.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/qio_avatar.dart';
import '../widgets/qio_badge.dart';
import '../widgets/onboarding_tour.dart';
import '../widgets/qio_card.dart';
import '../widgets/qio_empty_state.dart';
import '../widgets/qio_skeleton.dart';
import '../widgets/queue_panel/status_message_dialog.dart';
import '../widgets/qio_responsive_body.dart';
import 'account_screen.dart';
import 'create_queue_screen.dart';
import 'groups_screen.dart';
import 'join_operator_screen.dart';
import 'metrics_screen.dart';
import 'qr_poster_screen.dart';
import 'queue_panel_screen.dart';
import '../theme/qio_palette.dart';

enum _AccountAction { account, operator }

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.auth,
    this.queues,
    this.operators,
    this.enableIntegrations = true,
    this.prompts,
  });

  final AuthService? auth;
  final QueueService? queues;
  final OperatorService? operators;
  @visibleForTesting
  final bool enableIntegrations;
  @visibleForTesting
  final HomePrompts? prompts;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  QueueService get _queues => widget.queues ?? QueueService.instance;
  OperatorService get _operators =>
      widget.operators ?? OperatorService.instance;

  late final HomeController _controller = HomeController(
    ownedSource: _queues.watchOwnerQueues,
    operatingSource: _operators.watchMyOperatorQueues,
    requestsSource: _operators.watchMyRequests,
  );

  StreamSubscription<Uri>? _linkSub;
  HomePrompts? _prompts;
  String _query = '';
  final _searchController = TextEditingController();
  QueueSort _sort = QueueSort.name;
  final Map<String, int> _waiting = {};
  final Map<String, StreamSubscription<int>> _waitingSubs = {};

  @override
  void initState() {
    super.initState();
    QueueSortPrefs.load().then((sort) {
      if (!mounted) return;
      setState(() => _sort = sort);
      _syncWaitingSubs();
    });
    _controller.addListener(_syncWaitingSubs);
    _prompts =
        widget.prompts ??
        (widget.enableIntegrations ? _defaultPrompts() : null);
    if (_prompts != null) _controller.addListener(_onControllerChanged);
    if (!widget.enableIntegrations) return;
    final links = AppLinks();
    links.getInitialLink().then((uri) {
      if (uri != null && mounted) _openLink(uri);
    });
    _linkSub = links.uriLinkStream.listen(_openLink);
    if (PushService.instance.supported) _initPush();
  }

  StreamSubscription<RemoteMessage>? _pushSub;

  Future<void> _initPush() async {
    try {
      await PushService.instance.registerIfAllowed();
    } on Exception {
      // push is optional
    }
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    final initialId = initial == null ? null : queueIdFromPush(initial.data);
    if (initialId != null && mounted) _openQueue(initialId);
    _pushSub = FirebaseMessaging.onMessageOpenedApp.listen((m) {
      final id = queueIdFromPush(m.data);
      if (id != null) _openQueue(id);
    });
  }

  HomePrompts _defaultPrompts() => HomePrompts(
    runTour: _runTour,
    shouldPromptPush: () async =>
        PushService.instance.supported &&
        await PushService.instance.shouldPrompt(),
    askPush: _askForPush,
    canShowDialog: () => mounted,
  );

  bool _wasCurrent = true;

  bool _routeCurrent() => ModalRoute.of(context)?.isCurrent ?? true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = _routeCurrent();
    final returned = current && !_wasCurrent;
    _wasCurrent = current;
    if (returned && _prompts != null) _onControllerChanged();
  }

  void _syncWaitingSubs() {
    final needed = {
      ..._controller.ownedQueues.map((q) => q.id),
      ..._controller.operatingQueues.map((o) => o.queueId),
    };
    for (final id in _waitingSubs.keys.toList()) {
      if (!needed.contains(id)) {
        _waitingSubs.remove(id)?.cancel();
        _waiting.remove(id);
      }
    }
    for (final id in needed) {
      if (_waitingSubs.containsKey(id)) continue;
      _waitingSubs[id] = _queues.watchWaitingCount(id).listen((count) {
        if (!mounted) return;
        setState(() => _waiting[id] = count);
      }, onError: (_) {});
    }
  }

  void _setSort(QueueSort sort) {
    setState(() => _sort = sort);
    _syncWaitingSubs();
    QueueSortPrefs.save(sort);
  }

  void _onControllerChanged() {
    if (_controller.isLoading || _controller.hasError) return;
    final hasOwned = _controller.ownedQueues.isNotEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prompts?.onQueues(hasOwned: hasOwned, routeFree: _routeCurrent);
    });
  }

  Future<void> _askForPush() async {
    final l10n = AppLocalizations.of(context);
    await PushService.instance.markPrompted();
    if (!mounted) return;
    final enable = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.pushPromptTitle),
        content: Text(l10n.pushPromptBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.pushPromptNotNow),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.pushPromptEnable),
          ),
        ],
      ),
    );
    if (enable == true) await PushService.instance.enable();
  }

  Future<void> _openLink(Uri uri) async {
    final queueId = queueIdFromLink(uri);
    if (queueId == null) return;
    await _openQueue(queueId);
  }

  Future<void> _openQueue(String queueId) async {
    final access = await _queues.resolveAccess(queueId);
    if (!mounted) return;
    if (access == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).linkForCustomers)),
      );
      await launchUrl(
        clientUrlForQueue(queueId),
        mode: LaunchMode.externalApplication,
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QueuePanelScreen(
          queueId: queueId,
          queueName: access.queue.name,
          isOwner: access.isOwner,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.removeListener(_syncWaitingSubs);
    _searchController.dispose();
    for (final sub in _waitingSubs.values) {
      sub.cancel();
    }
    _linkSub?.cancel();
    _pushSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  final _fabKey = GlobalKey();
  final _accountKey = GlobalKey();
  final _firstQueueKey = GlobalKey();

  Future<void> _runTour() async {
    if (!mounted) return;
    final hasOwned = _controller.ownedQueues.isNotEmpty;
    final l10n = AppLocalizations.of(context);
    await showOnboardingTour(context, OnboardingTour.home, [
      OnboardingStep(
        key: _fabKey,
        title: l10n.tourHomeFabTitle,
        body: l10n.tourHomeFabBody,
        shape: ShapeLightFocus.Circle,
        above: true,
      ),
      if (hasOwned)
        OnboardingStep(
          key: _firstQueueKey,
          title: l10n.tourHomeQueueTitle,
          body: l10n.tourHomeQueueBody,
        ),
      OnboardingStep(
        key: _accountKey,
        title: l10n.tourHomeAccountTitle,
        body: l10n.tourHomeAccountBody,
        shape: ShapeLightFocus.Circle,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = (widget.auth ?? AuthService.instance).currentUser;
    return Scaffold(
      backgroundColor: context.qio.gray100,
      appBar: AppBar(
        backgroundColor: context.qio.surface,
        title: Text(
          l10n.myQueues,
          style: context.qioText.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: context.qio.textPrimary,
          ),
        ),
        actions: [
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => _controller.ownedQueues.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: l10n.groups,
                    icon: const Icon(
                      Icons.folder_outlined,
                      color: QioColors.primary,
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GroupsScreen()),
                    ),
                  ),
          ),
          IconButton(
            tooltip: l10n.metricsTooltip,
            icon: const Icon(Icons.bar_chart, color: QioColors.primary),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const MetricsScreen())),
          ),
          PopupMenuButton<_AccountAction>(
            key: _accountKey,
            tooltip: l10n.accountTitle,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onSelected: (action) => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => switch (action) {
                  _AccountAction.account => const AccountScreen(),
                  _AccountAction.operator => const JoinOperatorScreen(),
                },
              ),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: _AccountAction.account,
                child: Text(l10n.accountTitle),
              ),
              PopupMenuItem(
                value: _AccountAction.operator,
                child: Text(l10n.joinAsOperator),
              ),
            ],
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: QioAvatar(
                  name: user?.displayName ?? user?.email ?? 'Q',
                  size: 36,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: QioResponsiveBody(
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.hasError) {
              return QioErrorState(onRetry: _controller.retry);
            }
            if (_controller.isLoading) return const QioSkeletonList();
            return _buildBody(
              _controller.ownedQueues,
              _controller.operatingQueues,
              _controller.pendingRequests,
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: _fabKey,
        tooltip: l10n.createQueue,
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CreateQueueScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(
    List<Queue> owned,
    List<QueueOperator> operating,
    List<OperatorRequest> requests,
  ) {
    final l10n = AppLocalizations.of(context);
    if (owned.isEmpty && operating.isEmpty && requests.isEmpty) {
      return QioEmptyState(
        icon: Icons.qr_code_2,
        title: l10n.emptyQueuesTitle,
        message: l10n.emptyQueuesBody,
        actionLabel: l10n.createQueue,
        onAction: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CreateQueueScreen())),
        secondaryLabel: l10n.joinAsOperator,
        onSecondary: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const JoinOperatorScreen())),
      );
    }
    final showHeaders = operating.isNotEmpty || requests.isNotEmpty;
    final tools = showQueueTools(owned.length);
    final visible = tools
        ? filterAndSortQueues(
            owned,
            query: _query,
            sort: _sort,
            waiting: _waiting,
          )
        : owned;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (showHeaders && owned.isNotEmpty) _sectionTitle(l10n.sectionOwner),
        if (tools) _buildTools(l10n),
        if (tools && visible.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              l10n.noQueuesMatch,
              textAlign: TextAlign.center,
              style: context.qioText.body.copyWith(
                color: context.qio.textSecondary,
              ),
            ),
          ),
        ],
        for (final q in visible) ...[
          SizedBox(
            key: q == visible.first ? _firstQueueKey : null,
            child: _QueueCard(
              key: ValueKey(q.id),
              queue: q,
              isOwner: true,
              waiting: _waiting[q.id] ?? 0,
              queues: _queues,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (operating.isNotEmpty) _sectionTitle(l10n.sectionOperator),
        for (final op in operating) ...[
          _OperatorQueueCard(
            key: ValueKey('op-${op.queueId}'),
            operator: op,
            waiting: _waiting[op.queueId] ?? 0,
            queues: _queues,
          ),
          const SizedBox(height: 16),
        ],
        if (requests.isNotEmpty) _sectionTitle(l10n.sectionRequests),
        for (final r in requests) ...[
          _RequestCard(request: r, operators: _operators),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildTools(AppLocalizations l10n) {
    String label(QueueSort sort) => switch (sort) {
      QueueSort.name => l10n.sortByName,
      QueueSort.recent => l10n.sortByRecent,
      QueueSort.waiting => l10n.sortByWaiting,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.searchQueuesHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: l10n.clear,
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                isDense: false,
                constraints: const BoxConstraints(minHeight: 48),
              ),
            ),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<QueueSort>(
            tooltip: l10n.sortQueues,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            initialValue: _sort,
            onSelected: _setSort,
            itemBuilder: (_) => [
              for (final sort in QueueSort.values)
                CheckedPopupMenuItem(
                  value: sort,
                  checked: sort == _sort,
                  child: Text(label(sort)),
                ),
            ],
            child: const SizedBox(
              width: 48,
              height: 48,
              child: Icon(Icons.sort),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: context.qioText.label.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: context.qio.gray700,
        ),
      ),
    );
  }
}

class _QueueCard extends StatefulWidget {
  const _QueueCard({
    super.key,
    required this.queue,
    required this.isOwner,
    required this.waiting,
    required this.queues,
  });

  final Queue queue;
  final bool isOwner;
  final int waiting;
  final QueueService queues;

  @override
  State<_QueueCard> createState() => _QueueCardState();
}

class _QueueCardState extends State<_QueueCard> {
  bool _busy = false;

  Future<void> _toggleStatus() async {
    if (_busy) return;
    final q = widget.queue;
    final target = q.status == QueueStatus.open
        ? QueueStatus.paused
        : QueueStatus.open;
    StatusChange? change;
    if (target != QueueStatus.open) {
      change = await showStatusMessageDialog(context, target);
      if (change == null || !mounted) return;
    }
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await widget.queues.updateQueueStatus(
        q.id,
        target,
        message: change?.message,
        resumeAt: change?.resumeAt,
      );
    } on Exception catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(describeActionError(e).message(l10n)),
            backgroundColor: QioColors.error,
          ),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openQr() {
    final q = widget.queue;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QrPosterScreen(
          queueName: q.name,
          joinUrl: widget.queues.queueJoinUrl(q.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final q = widget.queue;
    final isOwner = widget.isOwner;
    return QioCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MergeSemantics(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QueuePanelScreen(
                    queueId: q.id,
                    queueName: q.name,
                    isOwner: isOwner,
                  ),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, isOwner ? 8 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            q.name,
                            style: context.qioText.heading3.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.qio.textPrimary,
                            ),
                          ),
                        ),
                        QioBadge(
                          label: q.status.label(l10n),
                          status: switch (q.status) {
                            QueueStatus.open => QioBadgeStatus.open,
                            QueueStatus.paused => QioBadgeStatus.paused,
                            QueueStatus.closed => QioBadgeStatus.closed,
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.waitingCount(widget.waiting),
                      style: context.qioText.body.copyWith(
                        fontSize: 14,
                        color: context.qio.gray700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isOwner
                          ? l10n.createdOn(q.createdAt)
                          : l10n.youAreOperator,
                      style: context.qioText.caption.copyWith(
                        fontSize: 12,
                        color: context.qio.gray400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isOwner)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Wrap(
                spacing: 8,
                children: [
                  _QuickAction(
                    icon: q.status == QueueStatus.open
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    label: q.status == QueueStatus.open
                        ? l10n.pause
                        : l10n.reopen,
                    semanticLabel: q.status == QueueStatus.open
                        ? l10n.quickPauseLabel(q.name)
                        : l10n.quickReopenLabel(q.name),
                    onPressed: _busy ? null : _toggleStatus,
                  ),
                  _QuickAction(
                    icon: Icons.qr_code_2,
                    label: l10n.quickQr,
                    semanticLabel: l10n.quickQrLabel(q.name),
                    onPressed: _openQr,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onPressed,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.padded,
          foregroundColor: context.qio.primaryText,
        ),
      ),
    );
  }
}

class _OperatorQueueCard extends StatefulWidget {
  const _OperatorQueueCard({
    super.key,
    required this.operator,
    required this.waiting,
    required this.queues,
  });

  final QueueOperator operator;
  final int waiting;
  final QueueService queues;

  @override
  State<_OperatorQueueCard> createState() => _OperatorQueueCardState();
}

class _OperatorQueueCardState extends State<_OperatorQueueCard> {
  late final Stream<Queue> _queueStream = widget.queues.watchQueue(
    widget.operator.queueId,
  );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Queue>(
      stream: _queueStream,
      builder: (context, snap) {
        final queue = snap.data;
        if (queue == null) {
          return QioCard(
            padding: const EdgeInsets.all(20),
            child: Text(
              widget.operator.queueName,
              style: context.qioText.heading3.copyWith(
                color: context.qio.gray400,
              ),
            ),
          );
        }
        return _QueueCard(
          queue: queue,
          isOwner: false,
          waiting: widget.waiting,
          queues: widget.queues,
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.operators});

  final OperatorRequest request;
  final OperatorService operators;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pending = request.status == OperatorRequestStatus.pending;
    return QioCard(
      padding: const EdgeInsets.all(20),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OperatorPendingScreen(
            queueId: request.queueId,
            queueName: request.queueName,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            pending ? Icons.hourglass_top : Icons.block,
            color: pending ? QioColors.warning : QioColors.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.queueName,
                  style: context.qioText.bodyMedium.copyWith(
                    color: context.qio.textPrimary,
                  ),
                ),
                Text(switch (request.status) {
                  OperatorRequestStatus.removed => l10n.requestRemovedStatus,
                  OperatorRequestStatus.rejected => l10n.requestRejectedStatus,
                  _ => l10n.awaitingApproval,
                }, style: context.qioText.caption.copyWith(fontSize: 12)),
              ],
            ),
          ),
          if (!pending)
            IconButton(
              tooltip: l10n.dismiss,
              icon: Icon(Icons.close, color: context.qio.gray400),
              onPressed: () => operators.cancelMyRequest(request.queueId),
            ),
        ],
      ),
    );
  }
}
