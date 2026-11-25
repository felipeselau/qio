import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/queue_goals.dart';
import '../../services/goal_risk.dart';
import '../../services/queue_service.dart';
import '../../theme/qio_colors.dart';
import '../../theme/qio_palette.dart';
import '../../theme/qio_text_styles.dart';
import '../bi_bars.dart';

class GoalRiskBanner extends StatefulWidget {
  const GoalRiskBanner({
    super.key,
    required this.queueId,
    required this.goals,
    required this.waiting,
    required this.manualAvgMin,
    this.queues,
  });

  final String queueId;
  final QueueGoals? goals;
  final int waiting;
  final int manualAvgMin;
  final QueueService? queues;

  @override
  State<GoalRiskBanner> createState() => _GoalRiskBannerState();
}

class _GoalRiskBannerState extends State<GoalRiskBanner> {
  StreamSubscription<double?>? _sub;
  double? _auto;

  bool get _active => widget.goals?.maxWaitMin != null;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(GoalRiskBanner old) {
    super.didUpdateWidget(old);
    if (old.queueId != widget.queueId ||
        _active != (old.goals?.maxWaitMin != null)) {
      _sync();
    }
  }

  void _sync() {
    _sub?.cancel();
    _sub = null;
    if (!_active) {
      _auto = null;
      return;
    }
    _sub = (widget.queues ?? QueueService.instance)
        .watchAvgServiceMinAuto(widget.queueId)
        .listen((v) {
          if (mounted) setState(() => _auto = v);
        }, onError: (_) {});
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goals = widget.goals;
    if (goals == null || !_active) return const SizedBox.shrink();
    final est = estimatedWaitMin(
      widget.waiting,
      auto: _auto,
      manual: widget.manualAvgMin,
    );
    if (!waitGoalAtRisk(est, goals)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final color = biBarColor(context, QioColors.warning);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        liveRegion: true,
        container: true,
        child: Container(
          key: const ValueKey('goal-risk-banner'),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.qio.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: context.qio.statusPausedText,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.goalRiskTitle, style: context.qioText.bodyMedium),
                    const SizedBox(height: 4),
                    Text(
                      l10n.goalRiskBody(widget.waiting, est, goals.maxWaitMin!),
                      key: const ValueKey('goal-risk-body'),
                      style: context.qioText.body,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.goalRiskAction,
                      key: const ValueKey('goal-risk-action'),
                      style: context.qioText.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
