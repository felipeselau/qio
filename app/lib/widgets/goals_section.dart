import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/goal_metrics.dart';
import '../services/metrics_export.dart';
import '../theme/qio_palette.dart';
import '../theme/qio_text_styles.dart';
import 'bi_bars.dart';
import 'bi_info.dart';
import 'qio_card.dart';

const int _maxMissedDays = 10;

String goalPct(int? v) => v == null ? '—' : '$v%';

String _dayKey(DateTime d) =>
    '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';

class GoalsSection extends StatelessWidget {
  const GoalsSection({super.key, required this.report});

  final GoalReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!report.hasGoals) {
      return QioCard(
        key: const ValueKey('goals-section'),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.goalsSectionTitle,
                  style: context.qioText.heading3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.goalsCtaTitle,
                key: const ValueKey('goals-empty-cta'),
                style: context.qioText.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(l10n.goalsCtaBody, style: context.qioText.body),
            ],
          ),
        ),
      );
    }
    return Column(
      key: const ValueKey('goals-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.goalsSectionTitle, style: context.qioText.heading3),
        ),
        const SizedBox(height: 4),
        Text(l10n.goalsSectionSubtitle, style: context.qioText.caption),
        Text(
          l10n.goalsQueuesCount(report.queuesWithGoals),
          key: const ValueKey('goals-queues-count'),
          style: context.qioText.caption,
        ),
        const SizedBox(height: 8),
        if (report.wait.configured > 0) ...[
          _GoalCard(
            id: 'wait',
            title: l10n.goalsWaitCardTitle,
            indicator: BiIndicator.goalWait,
            data: report.wait,
          ),
          const SizedBox(height: 12),
        ],
        if (report.service.configured > 0) ...[
          _GoalCard(
            id: 'service',
            title: l10n.goalsServiceCardTitle,
            indicator: BiIndicator.goalService,
            data: report.service,
          ),
          const SizedBox(height: 12),
        ],
        _MissedCard(report: report),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.id,
    required this.title,
    required this.indicator,
    required this.data,
  });

  final String id;
  final String title;
  final BiIndicator indicator;
  final GoalIndicator data;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final bucket = data.overall;
    final reliable = data.reliable(defaultGoalMinSamples);
    final days = data.days;
    return QioCard(
      key: ValueKey('goals-$id-card'),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BiTitle(text: title, indicator: indicator),
            const SizedBox(height: 8),
            if (!data.hasData)
              Text(
                l10n.goalsNoSamples,
                key: ValueKey('goals-$id-empty'),
                style: context.qioText.body,
              )
            else ...[
              Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    goalPct(bucket.pctFloor),
                    key: ValueKey('goals-$id-pct'),
                    style: context.qioText.heading2,
                  ),
                  if (reliable) _MetBadge(id: id, met: bucket.met),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.goalsTargetLine(bucket.targetPct!.round()),
                key: ValueKey('goals-$id-target'),
                style: context.qioText.body,
              ),
              Text(
                l10n.goalsCounts(bucket.ok, bucket.total),
                key: ValueKey('goals-$id-counts'),
                style: context.qioText.caption,
              ),
              if (!reliable)
                Text(
                  l10n.goalsSmallSample(defaultGoalMinSamples),
                  key: ValueKey('goals-$id-small'),
                  style: context.qioText.caption,
                ),
              if (days.length > 1) ...[
                const SizedBox(height: 12),
                Text(l10n.goalsDailyTitle, style: context.qioText.label),
                const SizedBox(height: 4),
                DayBars(
                  key: ValueKey('goals-$id-daily'),
                  fractions: [for (final d in days) d.bucket.pct],
                  belowTarget: [for (final d in days) !d.bucket.met],
                  targetFraction: (bucket.targetPct! / 100).clamp(0.0, 1.0),
                  startLabel: shortDate(locale, days.first.day),
                  endLabel: shortDate(locale, days.last.day),
                  semantics: l10n.goalsDailySemantics(
                    days.length,
                    days.where((d) => !d.bucket.met).length,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MetBadge extends StatelessWidget {
  const _MetBadge({required this.id, required this.met});

  final String id;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = met
        ? context.qio.statusOpenText
        : context.qio.statusPausedText;
    return Container(
      key: ValueKey('goals-$id-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(
              met ? Icons.check_circle_outline : Icons.warning_amber_rounded,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              met ? l10n.goalsMet : l10n.goalsNotMet,
              style: context.qioText.caption.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissedCard extends StatelessWidget {
  const _MissedCard({required this.report});

  final GoalReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.localeName;
    final kinds = [
      if (report.wait.configured > 0) ('wait', l10n.goalsKindWait, report.wait),
      if (report.service.configured > 0)
        ('service', l10n.goalsKindService, report.service),
    ];
    final any = kinds.any(
      (k) => k.$3.missedDays.isNotEmpty || k.$3.missedHours.isNotEmpty,
    );
    final worst = kinds.where((k) => k.$3.worstOverMin != null).toList();
    return QioCard(
      key: const ValueKey('goals-missed-card'),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BiTitle(
              text: l10n.goalsMissedTitle,
              indicator: BiIndicator.goalMissed,
            ),
            const SizedBox(height: 8),
            if (!any)
              Text(
                l10n.goalsMissedNone(defaultGoalMinSamples),
                key: const ValueKey('goals-missed-none'),
                style: context.qioText.body,
              ),
            for (final (id, kind, data) in kinds) ...[
              for (final d in data.missedDays.reversed.take(_maxMissedDays))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    l10n.goalsMissedDayRow(
                      kind,
                      shortDate(locale, d.day),
                      d.bucket.pctFloor!,
                      d.bucket.ok,
                      d.bucket.total,
                      d.bucket.targetPct!.round(),
                    ),
                    key: ValueKey('goals-missed-$id-${_dayKey(d.day)}'),
                    style: context.qioText.body,
                  ),
                ),
              if (data.missedDays.length > _maxMissedDays)
                Text(
                  l10n.goalsMissedMore(data.missedDays.length - _maxMissedDays),
                  key: ValueKey('goals-missed-$id-more'),
                  style: context.qioText.caption,
                ),
              if (data.missedHours.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    l10n.goalsMissedHoursRow(
                      kind,
                      data.missedHours.map((h) => hourLabel(h.hour)).join(', '),
                    ),
                    key: ValueKey('goals-missed-$id-hours'),
                    style: context.qioText.body,
                  ),
                ),
            ],
            if (worst.isEmpty && kinds.any((k) => k.$3.hasData)) ...[
              const SizedBox(height: 4),
              Text(
                l10n.goalsNoViolation,
                key: const ValueKey('goals-no-violation'),
                style: context.qioText.caption,
              ),
            ],
            for (final (id, _, data) in worst) ...[
              const SizedBox(height: 4),
              Text(
                id == 'wait'
                    ? l10n.goalsWorstWait(
                        data.worstOverMin!.ceil(),
                        shortDate(locale, data.worstDay!),
                      )
                    : l10n.goalsWorstService(
                        data.worstOverMin!.ceil(),
                        shortDate(locale, data.worstDay!),
                      ),
                key: ValueKey('goals-worst-$id'),
                style: context.qioText.body,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
