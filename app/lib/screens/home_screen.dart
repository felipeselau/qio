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
import '../services/auth_service.dart';
import '../services/deep_link.dart';
import '../services/push_service.dart';
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
import '../widgets/qio_responsive_body.dart';
import 'account_screen.dart';
import 'create_queue_screen.dart';
import 'groups_screen.dart';
import 'join_operator_screen.dart';
import 'metrics_screen.dart';
import 'queue_panel_screen.dart';
import '../theme/qio_palette.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.auth,
    this.queues,
    this.operators,
    this.enableIntegrations = true,
  });

  final AuthService? auth;
  final QueueService? queues;
  final OperatorService? operators;
  @visibleForTesting
  final bool enableIntegrations;

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

  @override
  void initState() {
    super.initState();
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
    if (await PushService.instance.shouldPrompt() && mounted) {
      await _askForPush();
    }
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
    _linkSub?.cancel();
    _pushSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  final _fabKey = GlobalKey();
  final _operatorKey = GlobalKey();
  final _firstQueueKey = GlobalKey();
  bool _tourScheduled = false;

  void _scheduleTour(bool hasOwned) {
    if (_tourScheduled || !widget.enableIntegrations) return;
    _tourScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      showOnboardingTour(context, OnboardingTour.home, [
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
          key: _operatorKey,
          title: l10n.tourHomeOperatorTitle,
          body: l10n.tourHomeOperatorBody,
          shape: ShapeLightFocus.Circle,
        ),
      ]);
    });
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
          IconButton(
            key: _operatorKey,
            tooltip: l10n.joinAsOperator,
            icon: const Icon(Icons.badge_outlined, color: QioColors.primary),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const JoinOperatorScreen()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Semantics(
              button: true,
              label: l10n.accountTitle,
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AccountScreen()),
                ),
                child: QioAvatar(
                  name: user?.displayName ?? user?.email ?? 'Q',
                  size: 36,
                ),
              ),
            ),
          ),
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
            _scheduleTour(_controller.ownedQueues.isNotEmpty);
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
      );
    }
    final showHeaders = operating.isNotEmpty || requests.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (showHeaders && owned.isNotEmpty) _sectionTitle(l10n.sectionOwner),
        for (final q in owned) ...[
          _QueueCard(
            key: q == owned.first ? _firstQueueKey : null,
            queue: q,
            isOwner: true,
            queues: _queues,
          ),
          const SizedBox(height: 16),
        ],
        if (operating.isNotEmpty) _sectionTitle(l10n.sectionOperator),
        for (final op in operating) ...[
          _OperatorQueueCard(operator: op, queues: _queues),
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

class _QueueCard extends StatelessWidget {
  const _QueueCard({
    super.key,
    required this.queue,
    required this.isOwner,
    required this.queues,
  });

  final Queue queue;
  final bool isOwner;
  final QueueService queues;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final q = queue;
    return MergeSemantics(
      child: QioCard(
        padding: const EdgeInsets.all(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QueuePanelScreen(
              queueId: q.id,
              queueName: q.name,
              isOwner: isOwner,
            ),
          ),
        ),
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
            StreamBuilder<int>(
              stream: queues.watchWaitingCount(q.id),
              builder: (context, snap) {
                final count = snap.data ?? 0;
                return Text(
                  l10n.waitingCount(count),
                  style: context.qioText.body.copyWith(
                    fontSize: 14,
                    color: context.qio.gray700,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              isOwner ? l10n.createdOn(q.createdAt) : l10n.youAreOperator,
              style: context.qioText.caption.copyWith(
                fontSize: 12,
                color: context.qio.gray400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OperatorQueueCard extends StatefulWidget {
  const _OperatorQueueCard({required this.operator, required this.queues});

  final QueueOperator operator;
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
        return _QueueCard(queue: queue, isOwner: false, queues: widget.queues);
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
