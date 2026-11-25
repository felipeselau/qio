import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/abandonment_metrics.dart';
import '../services/metrics_export.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_palette.dart';
import '../theme/qio_text_styles.dart';
import 'bi_bars.dart';
import 'bi_info.dart';
import 'qio_card.dart';

String _pct(double v) => '${(v * 100).round()}%';

class AbandonmentSection extends StatelessWidget {
  const AbandonmentSection({
    super.key,
    required this.report,
    this.queueName,
    this.truncated = false,
    this.historyLimit = 0,
  });

  final AbandonmentReport report;
  final String? queueName;
  final bool truncated;
  final int historyLimit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      key: const ValueKey('abandon-section'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(l10n.abandonTitle, style: context.qioText.heading3),
        ),
        const SizedBox(height: 4),
        Text(l10n.abandonSubtitle, style: context.qioText.caption),
        if (queueName != null)
          Text(
            l10n.abandonScopeQueue(queueName!),
            key: const ValueKey('abandon-scope'),
            style: context.qioText.caption,
          ),
        if (truncated)
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.historyTruncatedWarning(historyLimit),
              key: const ValueKey('abandon-truncated'),
              style: context.qioText.caption,
            ),
          ),
        const SizedBox(height: 8),
        _WaitCard(report: report),
        const SizedBox(height: 12),
        _EstimateCard(report: report),
        const SizedBox(height: 12),
        _HourCard(report: report),
        const SizedBox(height: 12),
        _CapacityCard(report: report),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.text, required this.indicator, this.hint});

  final String text;
  final BiIndicator indicator;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(text, style: context.qioText.bodyMedium),
              ),
            ),
            BiInfoButton(indicator: indicator),
          ],
        ),
        if (hint != null) Text(hint!, style: context.qioText.caption),
      ],
    );
  }
}

class _WaitCard extends StatelessWidget {
  const _WaitCard({required this.report});

  final AbandonmentReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bands = report.waitBands;
    final max = bands.fold<double>(
      0,
      (m, b) => (b.ratePer10Min ?? 0) > m ? b.ratePer10Min! : m,
    );
    final infl = report.inflection;
    return QioCard(
      key: const ValueKey('abandon-wait-card'),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Title(
              text: l10n.abandonWaitTitle,
              indicator: BiIndicator.abandonWait,
              hint: l10n.abandonWaitHint,
            ),
            const SizedBox(height: 8),
            if (!report.hasWaitRates)
              Text(
                l10n.abandonWaitEmpty(defaultAbandonMinSamples),
                key: const ValueKey('abandon-wait-empty'),
                style: context.qioText.body,
              )
            else ...[
              RateBarList(
                prefix: 'abandon-wait',
                items: [
                  for (final b in bands)
                    () {
                      final label = bandLabel(l10n, b.startMin, b.endMin);
                      final r = b.ratePer10Min;
                      return RateBarItem(
                        id: '${b.startMin}',
                        label: label,
                        value: r == null ? '—' : _pct(r),
                        fraction: fractionOf(r, max),
                        highlight: identical(b, infl),
                        spoken: r == null
                            ? l10n.abandonBarNoData(label)
                            : '${l10n.abandonBarSpoken(label, (r * 100).round())}. '
                                  '${l10n.abandonBarCounts(b.left, b.atRisk)}',
                      );
                    }(),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      infl == null
                          ? l10n.abandonInflectionNone(inflectionLimitPct())
                          : l10n.abandonInflectionFound(
                              bandLabel(l10n, infl.startMin, infl.endMin),
                              inflectionLimitPct(),
                            ),
                      key: const ValueKey('abandon-inflection'),
                      style: context.qioText.body,
                    ),
                  ),
                  const BiInfoButton(indicator: BiIndicator.abandonInflection),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EstimateCard extends StatelessWidget {
  const _EstimateCard({required this.report});

  final AbandonmentReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bands = report.estimateBands;
    final max = bands.fold<double>(
      0,
      (m, b) => (b.rate ?? 0) > m ? b.rate! : m,
    );
    final acc = report.accuracy;
    return QioCard(
      key: const ValueKey('abandon-estimate-card'),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Title(
              text: l10n.abandonEstimateTitle,
              indicator: BiIndicator.abandonEstimate,
              hint: l10n.abandonEstimateHint,
            ),
            const SizedBox(height: 8),
            if (!report.hasEstimates)
              Text(
                l10n.abandonEstimateEmpty,
                key: const ValueKey('abandon-estimate-empty'),
                style: context.qioText.body,
              )
            else ...[
              if (!bands.any((b) => b.rate != null))
                Text(
                  l10n.abandonWaitEmpty(defaultAbandonMinSamples),
                  key: const ValueKey('abandon-estimate-sparse'),
                  style: context.qioText.body,
                )
              else
                RateBarList(
                  prefix: 'abandon-estimate',
                  items: [
                    for (final b in bands)
                      () {
                        final label = bandLabel(l10n, b.startMin, b.endMin);
                        final r = b.rate;
                        return RateBarItem(
                          id: '${b.startMin}',
                          label: label,
                          value: r == null ? '—' : _pct(r),
                          fraction: fractionOf(r, max),
                          spoken: r == null
                              ? l10n.abandonEstimateBarNoData(label)
                              : '${l10n.abandonEstimateBarSpoken(label, (r * 100).round())}. '
                                    '${l10n.abandonBarCounts(b.left, b.total)}',
                        );
                      }(),
                  ],
                ),
              const SizedBox(height: 12),
              _Title(
                text: l10n.estimateAccuracyTitle,
                indicator: BiIndicator.estimateAccuracy,
              ),
              if (acc.meanErrorMin == null)
                Text(
                  l10n.estimateAccuracyNone(defaultAbandonMinSamples),
                  key: const ValueKey('estimate-accuracy-none'),
                  style: context.qioText.body,
                )
              else ...[
                Text(
                  l10n.estimateAccuracyMean(
                    _signed(acc.meanErrorMin!),
                    acc.samples,
                  ),
                  key: const ValueKey('estimate-accuracy-mean'),
                  style: context.qioText.body,
                ),
                Text(
                  l10n.estimateAccuracyAbs(
                    acc.meanAbsErrorMin!.toStringAsFixed(1),
                  ),
                  key: const ValueKey('estimate-accuracy-abs'),
                  style: context.qioText.body,
                ),
                Text(l10n.estimateAccuracyHint, style: context.qioText.caption),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

String _signed(double v) => '${v > 0 ? '+' : ''}${v.toStringAsFixed(1)}';

class _HourCard extends StatelessWidget {
  const _HourCard({required this.report});

  final AbandonmentReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hours = report.hours;
    final maxRate = hours.fold<double>(
      0,
      (m, h) => (h.rate ?? 0) > m ? h.rate! : m,
    );
    final maxLeft = hours.fold<int>(0, (m, h) => h.left > m ? h.left : m);
    HourAbandonment? peak;
    for (final h in hours) {
      if (h.rate != null && (peak == null || h.rate! > peak.rate!)) peak = h;
    }
    String hourName(int h) => hourLabel(h);
    final spoken = [
      for (final h in hours)
        if (h.rate != null)
          l10n.abandonHourSpoken(
            hourName(h.hour),
            (h.rate! * 100).round(),
            h.left,
            h.total,
          )
        else if (h.total > 0)
          l10n.abandonHourNoRate(hourName(h.hour), h.left, h.total),
    ];
    return QioCard(
      key: const ValueKey('abandon-hour-card'),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Title(
              text: l10n.abandonHourTitle,
              indicator: BiIndicator.abandonHour,
            ),
            const SizedBox(height: 8),
            if (peak == null)
              Text(
                l10n.abandonHourEmpty(defaultAbandonMinSamples),
                key: const ValueKey('abandon-hour-empty'),
                style: context.qioText.body,
              )
            else ...[
              Text(l10n.abandonHourRateLabel, style: context.qioText.label),
              const SizedBox(height: 4),
              HourBars(
                key: const ValueKey('abandon-hour-rate-bars'),
                fractions: [for (final h in hours) fractionOf(h.rate, maxRate)],
                color: biBarColor(context, QioColors.warning),
                height: 80,
                semantics: spoken.join(', '),
              ),
              const SizedBox(height: 12),
              Text(l10n.abandonHourCountLabel, style: context.qioText.label),
              const SizedBox(height: 4),
              HourBars(
                key: const ValueKey('abandon-hour-count-bars'),
                fractions: [for (final h in hours) fractionOf(h.left, maxLeft)],
                color: biBarColor(context, QioColors.primary),
                height: 60,
                semantics: l10n.abandonHourCountLabel,
              ),
              const SizedBox(height: 8),
              if (peak.rate! > 0)
                Text(
                  l10n.abandonHourPeak(
                    hourName(peak.hour),
                    (peak.rate! * 100).round(),
                    peak.left,
                    peak.total,
                  ),
                  key: const ValueKey('abandon-hour-peak'),
                  style: context.qioText.body,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CapacityCard extends StatelessWidget {
  const _CapacityCard({required this.report});

  final AbandonmentReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hours = report.capacityHours;
    final alert = hours.isNotEmpty;
    final title = l10n.capacityCardTitle;
    final body = alert
        ? l10n.capacityCardBody(
            hours.map(hourLabel).join(', '),
            waitThresholdRounded(),
            inflectionLimitPct(),
          )
        : l10n.capacityCardNone;
    return Container(
      key: const ValueKey('abandon-capacity-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.qio.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alert
              ? biBarColor(context, QioColors.warning)
              : context.qio.gray200,
          width: alert ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  alert
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
                  color: alert
                      ? context.qio.statusPausedText
                      : context.qio.statusOpenText,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(title, style: context.qioText.bodyMedium),
                ),
              ),
              const BiInfoButton(indicator: BiIndicator.capacitySignal),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            key: const ValueKey('abandon-capacity-text'),
            style: context.qioText.body,
          ),
        ],
      ),
    );
  }
}
