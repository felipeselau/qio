import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../l10n/app_localizations.dart';
import '../models/operator.dart';
import '../models/queue.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';
import '../services/operator_service.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/qio_avatar.dart';
import '../widgets/qio_badge.dart';
import '../widgets/onboarding_tour.dart';
import '../widgets/qio_card.dart';
import 'account_screen.dart';
import 'create_queue_screen.dart';
import 'join_operator_screen.dart';
import 'queue_panel_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Stream<List<Queue>> _ownedStream = QueueService.instance
      .watchOwnerQueues();
  late final Stream<List<QueueOperator>> _operatingStream = OperatorService
      .instance
      .watchMyOperatorQueues();
  late final Stream<List<OperatorRequest>> _requestsStream = OperatorService
      .instance
      .watchMyRequests();
  final _fabKey = GlobalKey();
  final _operatorKey = GlobalKey();
  final _firstQueueKey = GlobalKey();
  bool _tourScheduled = false;

  void _scheduleTour(bool hasOwned) {
    if (_tourScheduled) return;
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
    final user = AuthService.instance.currentUser;
    return Scaffold(
      backgroundColor: QioColors.gray100,
      appBar: AppBar(
        backgroundColor: QioColors.surface,
        title: Text(
          l10n.myQueues,
          style: QioTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: QioColors.textPrimary,
          ),
        ),
        actions: [
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
      body: StreamBuilder<List<Queue>>(
        stream: _ownedStream,
        builder: (context, ownedSnap) {
          return StreamBuilder<List<QueueOperator>>(
            stream: _operatingStream,
            builder: (context, operatingSnap) {
              return StreamBuilder<List<OperatorRequest>>(
                stream: _requestsStream,
                builder: (context, requestsSnap) {
                  if (ownedSnap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  _scheduleTour((ownedSnap.data ?? []).isNotEmpty);
                  return _buildBody(
                    ownedSnap.data ?? [],
                    operatingSnap.data ?? [],
                    requestsSnap.data ?? [],
                  );
                },
              );
            },
          );
        },
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_2, size: 64, color: QioColors.gray300),
              const SizedBox(height: 16),
              Text(l10n.emptyQueuesTitle, style: QioTextStyles.heading2),
              const SizedBox(height: 8),
              Text(
                l10n.emptyQueuesBody,
                style: QioTextStyles.body.copyWith(
                  color: QioColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
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
          ),
          const SizedBox(height: 16),
        ],
        if (operating.isNotEmpty) _sectionTitle(l10n.sectionOperator),
        for (final op in operating) ...[
          _OperatorQueueCard(operator: op),
          const SizedBox(height: 16),
        ],
        if (requests.isNotEmpty) _sectionTitle(l10n.sectionRequests),
        for (final r in requests) ...[
          _RequestCard(request: r),
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
        style: QioTextStyles.label.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: QioColors.gray700,
        ),
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({super.key, required this.queue, required this.isOwner});

  final Queue queue;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final q = queue;
    return QioCard(
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
                  style: QioTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w600,
                    color: QioColors.textPrimary,
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
            stream: QueueService.instance.watchWaitingCount(q.id),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return Text(
                l10n.waitingCount(count),
                style: QioTextStyles.body.copyWith(
                  fontSize: 14,
                  color: QioColors.gray700,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            isOwner ? l10n.createdOn(q.createdAt) : l10n.youAreOperator,
            style: QioTextStyles.caption.copyWith(
              fontSize: 12,
              color: QioColors.gray400,
            ),
          ),
        ],
      ),
    );
  }
}

class _OperatorQueueCard extends StatefulWidget {
  const _OperatorQueueCard({required this.operator});

  final QueueOperator operator;

  @override
  State<_OperatorQueueCard> createState() => _OperatorQueueCardState();
}

class _OperatorQueueCardState extends State<_OperatorQueueCard> {
  late final Stream<Queue> _queueStream = QueueService.instance.watchQueue(
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
              style: QioTextStyles.heading3.copyWith(color: QioColors.gray400),
            ),
          );
        }
        return _QueueCard(queue: queue, isOwner: false);
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final OperatorRequest request;

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
                  style: QioTextStyles.bodyMedium.copyWith(
                    color: QioColors.textPrimary,
                  ),
                ),
                Text(switch (request.status) {
                  OperatorRequestStatus.removed => l10n.requestRemovedStatus,
                  OperatorRequestStatus.rejected => l10n.requestRejectedStatus,
                  _ => l10n.awaitingApproval,
                }, style: QioTextStyles.caption.copyWith(fontSize: 12)),
              ],
            ),
          ),
          if (!pending)
            IconButton(
              tooltip: l10n.dismiss,
              icon: Icon(Icons.close, color: QioColors.gray400),
              onPressed: () =>
                  OperatorService.instance.cancelMyRequest(request.queueId),
            ),
        ],
      ),
    );
  }
}
