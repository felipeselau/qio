import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/abandonment_metrics.dart';
import '../services/attendant_metrics.dart';
import '../services/goal_metrics.dart';
import '../services/operator_metrics.dart';
import '../services/staffing_metrics.dart';
import '../theme/qio_palette.dart';
import '../theme/qio_text_styles.dart';

enum BiIndicator {
  attendantThroughput,
  attendantService,
  attendantDeviation,
  attendantRate,
  attendantIdle,
  abandonWait,
  abandonInflection,
  abandonEstimate,
  estimateAccuracy,
  abandonHour,
  capacitySignal,
  goalWait,
  goalService,
  goalMissed,
  staffingService,
  staffingRequired,
  staffingObserved,
  staffingGap,
  seasonVolume,
  seasonPattern,
}

class BiInfoTexts {
  const BiInfoTexts({
    required this.name,
    required this.what,
    required this.how,
    required this.data,
    required this.use,
  });

  final String name;
  final String what;
  final String how;
  final String data;
  final String use;
}

String bandsText(List<int> edges) {
  final starts = [0, ...edges];
  return [
    for (var i = 0; i < starts.length; i++)
      i + 1 < starts.length ? '${starts[i]}–${starts[i + 1]}' : '${starts[i]}+',
  ].join(', ');
}

int inflectionLimitPct() => (defaultInflectionThreshold * 100).round();

int occupancyPct(double v) => (v * 100).round();

int waitThresholdRounded() => defaultWaitThresholdMin.round();

BiInfoTexts biInfoTexts(AppLocalizations l, BiIndicator i) {
  switch (i) {
    case BiIndicator.attendantThroughput:
      return BiInfoTexts(
        name: l.biNameAttendantThroughput,
        what: l.biWhatAttendantThroughput,
        how: l.biHowAttendantThroughput,
        data: l.biDataAttendantThroughput,
        use: l.biUseAttendantThroughput,
      );
    case BiIndicator.attendantService:
      return BiInfoTexts(
        name: l.biNameAttendantService,
        what: l.biWhatAttendantService,
        how: l.biHowAttendantService(minServiceSamples),
        data: l.biDataAttendantService,
        use: l.biUseAttendantService,
      );
    case BiIndicator.attendantDeviation:
      return BiInfoTexts(
        name: l.biNameAttendantDeviation,
        what: l.biWhatAttendantDeviation,
        how: l.biHowAttendantDeviation(minServiceSamples),
        data: l.biDataAttendantDeviation,
        use: l.biUseAttendantDeviation,
      );
    case BiIndicator.attendantRate:
      return BiInfoTexts(
        name: l.biNameAttendantRate,
        what: l.biWhatAttendantRate,
        how: l.biHowAttendantRate(defaultMinRateSamples, defaultMinWindowMin),
        data: l.biDataAttendantRate,
        use: l.biUseAttendantRate,
      );
    case BiIndicator.attendantIdle:
      return BiInfoTexts(
        name: l.biNameAttendantIdle,
        what: l.biWhatAttendantIdle,
        how: l.biHowAttendantIdle(defaultIdleCapMin, defaultMinRateSamples),
        data: l.biDataAttendantIdle,
        use: l.biUseAttendantIdle,
      );
    case BiIndicator.abandonWait:
      return BiInfoTexts(
        name: l.biNameAbandonWait,
        what: l.biWhatAbandonWait,
        how: l.biHowAbandonWait(
          bandsText(defaultWaitBandEdges),
          defaultAbandonMinSamples,
        ),
        data: l.biDataAbandonWait,
        use: l.biUseAbandonWait,
      );
    case BiIndicator.abandonInflection:
      return BiInfoTexts(
        name: l.biNameAbandonInflection,
        what: l.biWhatAbandonInflection,
        how: l.biHowAbandonInflection(inflectionLimitPct()),
        data: l.biDataAbandonInflection,
        use: l.biUseAbandonInflection,
      );
    case BiIndicator.abandonEstimate:
      return BiInfoTexts(
        name: l.biNameAbandonEstimate,
        what: l.biWhatAbandonEstimate,
        how: l.biHowAbandonEstimate(
          bandsText(defaultEstimateBandEdges),
          defaultAbandonMinSamples,
        ),
        data: l.biDataAbandonEstimate,
        use: l.biUseAbandonEstimate,
      );
    case BiIndicator.estimateAccuracy:
      return BiInfoTexts(
        name: l.biNameEstimateAccuracy,
        what: l.biWhatEstimateAccuracy,
        how: l.biHowEstimateAccuracy(defaultAbandonMinSamples),
        data: l.biDataEstimateAccuracy,
        use: l.biUseEstimateAccuracy,
      );
    case BiIndicator.abandonHour:
      return BiInfoTexts(
        name: l.biNameAbandonHour,
        what: l.biWhatAbandonHour,
        how: l.biHowAbandonHour(defaultAbandonMinSamples),
        data: l.biDataAbandonHour,
        use: l.biUseAbandonHour,
      );
    case BiIndicator.capacitySignal:
      return BiInfoTexts(
        name: l.biNameCapacitySignal,
        what: l.biWhatCapacitySignal,
        how: l.biHowCapacitySignal(
          waitThresholdRounded(),
          inflectionLimitPct(),
        ),
        data: l.biDataCapacitySignal,
        use: l.biUseCapacitySignal,
      );
    case BiIndicator.goalWait:
      return BiInfoTexts(
        name: l.biNameGoalWait,
        what: l.biWhatGoalWait,
        how: l.biHowGoalWait(defaultGoalMinSamples),
        data: l.biDataGoalWait,
        use: l.biUseGoalWait,
      );
    case BiIndicator.goalService:
      return BiInfoTexts(
        name: l.biNameGoalService,
        what: l.biWhatGoalService,
        how: l.biHowGoalService(defaultGoalMinSamples),
        data: l.biDataGoalService,
        use: l.biUseGoalService,
      );
    case BiIndicator.goalMissed:
      return BiInfoTexts(
        name: l.biNameGoalMissed,
        what: l.biWhatGoalMissed,
        how: l.biHowGoalMissed(defaultGoalMinSamples),
        data: l.biDataGoalMissed,
        use: l.biUseGoalMissed,
      );
    case BiIndicator.staffingService:
      return BiInfoTexts(
        name: l.biNameStaffingService,
        what: l.biWhatStaffingService,
        how: l.biHowStaffingService(defaultMinServiceSamples),
        data: l.biDataStaffingService,
        use: l.biUseStaffingService,
      );
    case BiIndicator.staffingRequired:
      return BiInfoTexts(
        name: l.biNameStaffingRequired,
        what: l.biWhatStaffingRequired,
        how: l.biHowStaffingRequired(occupancyPct(defaultTargetOccupancy)),
        data: l.biDataStaffingRequired,
        use: l.biUseStaffingRequired,
      );
    case BiIndicator.staffingObserved:
      return BiInfoTexts(
        name: l.biNameStaffingObserved,
        what: l.biWhatStaffingObserved,
        how: l.biHowStaffingObserved,
        data: l.biDataStaffingObserved,
        use: l.biUseStaffingObserved,
      );
    case BiIndicator.staffingGap:
      return BiInfoTexts(
        name: l.biNameStaffingGap,
        what: l.biWhatStaffingGap,
        how: l.biHowStaffingGap(defaultDeficitLimit),
        data: l.biDataStaffingGap,
        use: l.biUseStaffingGap,
      );
    case BiIndicator.seasonVolume:
      return BiInfoTexts(
        name: l.biNameSeasonVolume,
        what: l.biWhatSeasonVolume,
        how: l.biHowSeasonVolume(
          seasonWeeks,
          stableTrendPct.round(),
          minSeasonWeeks,
        ),
        data: l.biDataSeasonVolume,
        use: l.biUseSeasonVolume,
      );
    case BiIndicator.seasonPattern:
      return BiInfoTexts(
        name: l.biNameSeasonPattern,
        what: l.biWhatSeasonPattern,
        how: l.biHowSeasonPattern(
          seasonTopCells,
          recurrencePct,
          minSeasonWeeks,
        ),
        data: l.biDataSeasonPattern,
        use: l.biUseSeasonPattern,
      );
  }
}

Future<void> showBiInfoSheet(BuildContext context, BiIndicator indicator) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => BiInfoSheet(indicator: indicator),
  );
}

class BiInfoButton extends StatelessWidget {
  const BiInfoButton({super.key, required this.indicator});

  final BiIndicator indicator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final name = biInfoTexts(l10n, indicator).name;
    return IconButton(
      key: ValueKey('info-${indicator.name}'),
      tooltip: l10n.infoButtonSemantics(name),
      icon: Icon(Icons.info_outline, color: context.qio.gray600),
      onPressed: () => showBiInfoSheet(context, indicator),
    );
  }
}

class BiInfoSheet extends StatelessWidget {
  const BiInfoSheet({super.key, required this.indicator});

  final BiIndicator indicator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = biInfoTexts(l10n, indicator);
    return SingleChildScrollView(
      key: ValueKey('info-sheet-${indicator.name}'),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(t.name, style: context.qioText.heading2),
          ),
          _block(context, l10n.infoWhat, t.what),
          _block(context, l10n.infoHow, t.how),
          _block(context, l10n.infoData, t.data),
          _block(context, l10n.infoUse, t.use),
          const SizedBox(height: 16),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(
              key: const ValueKey('info-close'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.infoClose),
            ),
          ),
        ],
      ),
    );
  }

  Widget _block(BuildContext context, String label, String body) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(label, style: context.qioText.bodyMedium),
          ),
          const SizedBox(height: 4),
          Text(body, style: context.qioText.body),
        ],
      ),
    );
  }
}

class BiTitle extends StatelessWidget {
  const BiTitle({
    super.key,
    required this.text,
    required this.indicator,
    this.hint,
  });

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
