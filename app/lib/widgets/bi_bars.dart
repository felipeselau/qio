import 'package:flutter/material.dart';

import '../services/brand_palette.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_palette.dart';
import '../theme/qio_text_styles.dart';

Color biBarColor(BuildContext context, Color base, {Color? on}) =>
    ensureContrast(base, on ?? context.qio.card);

class HourBars extends StatelessWidget {
  const HourBars({
    super.key,
    required this.fractions,
    required this.semantics,
    this.color = QioColors.primary,
    this.height = 100,
  });

  final List<double?> fractions;
  final String semantics;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semantics,
      child: ExcludeSemantics(
        child: Column(
          children: [
            SizedBox(
              height: height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var h = 0; h < fractions.length; h++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1),
                        child: Container(
                          height: 2 + (height - 2) * (fractions[h] ?? 0),
                          decoration: BoxDecoration(
                            color: (fractions[h] ?? 0) == 0
                                ? context.qio.gray200
                                : color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            _AxisLabels(style: context.qioText.caption),
          ],
        ),
      ),
    );
  }
}

class _AxisLabels extends StatelessWidget {
  const _AxisLabels({required this.style});

  final TextStyle style;

  static const _hours = [0, 6, 12, 18, 23];

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(1) <= 1.3) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [for (final h in _hours) Text('${h}h', style: style)],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < _hours.length; i++)
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: i == 0
                  ? AlignmentDirectional.centerStart
                  : i == _hours.length - 1
                  ? AlignmentDirectional.centerEnd
                  : Alignment.center,
              child: Text('${_hours[i]}h', style: style),
            ),
          ),
      ],
    );
  }
}

double? fractionOf(num? v, num max) =>
    v == null || max <= 0 ? null : (v / max).clamp(0.0, 1.0).toDouble();

class RateBarItem {
  const RateBarItem({
    required this.id,
    required this.label,
    required this.value,
    required this.fraction,
    required this.spoken,
    this.highlight = false,
  });

  final String id;
  final String label;
  final String value;
  final double? fraction;
  final String spoken;
  final bool highlight;
}

class RateBarList extends StatelessWidget {
  const RateBarList({super.key, required this.items, required this.prefix});

  final List<RateBarItem> items;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final i in items)
          Semantics(
            container: true,
            label: i.spoken,
            child: ExcludeSemantics(
              child: Padding(
                key: ValueKey('$prefix-${i.id}'),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (i.highlight) ...[
                          Icon(
                            Icons.flag,
                            size: 16,
                            color: context.qio.statusPausedText,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            i.label,
                            style: i.highlight
                                ? context.qioText.bodyMedium
                                : context.qioText.body,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(i.value, style: context.qioText.bodyMedium),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LayoutBuilder(
                      builder: (context, c) => Stack(
                        children: [
                          Container(
                            height: 10,
                            width: c.maxWidth,
                            decoration: BoxDecoration(
                              color: context.qio.gray200,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          Container(
                            height: 10,
                            width: c.maxWidth * (i.fraction ?? 0),
                            decoration: BoxDecoration(
                              color: biBarColor(
                                context,
                                i.highlight
                                    ? QioColors.warning
                                    : QioColors.primary,
                                on: context.qio.gray200,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class DayBars extends StatelessWidget {
  const DayBars({
    super.key,
    required this.fractions,
    required this.semantics,
    required this.startLabel,
    required this.endLabel,
    this.targetFraction,
    this.belowTarget = const [],
    this.height = 80,
  });

  final List<double?> fractions;
  final List<bool> belowTarget;
  final double? targetFraction;
  final String semantics;
  final String startLabel;
  final String endLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final good = biBarColor(context, QioColors.primary);
    final bad = biBarColor(context, QioColors.warning);
    final target = targetFraction;
    return Semantics(
      label: semantics,
      child: ExcludeSemantics(
        child: Column(
          children: [
            SizedBox(
              height: height,
              child: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < fractions.length; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 1),
                            child: Container(
                              height: 2 + (height - 2) * (fractions[i] ?? 0),
                              decoration: BoxDecoration(
                                color: fractions[i] == null
                                    ? context.qio.gray200
                                    : (i < belowTarget.length && belowTarget[i])
                                    ? bad
                                    : good,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (target != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 2 + (height - 2) * target,
                      child: Container(
                        height: 1,
                        color: context.qio.textPrimary.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(startLabel, style: context.qioText.caption),
                Text(endLabel, style: context.qioText.caption),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
