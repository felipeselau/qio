import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/alerts_config.dart';
import '../../theme/qio_text_styles.dart';
import '../qio_card.dart';

class AlertsForm extends StatelessWidget {
  const AlertsForm({super.key, required this.value, required this.onChanged});

  final AlertsConfig value;
  final ValueChanged<AlertsConfig> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final config = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QioCard(
          child: SwitchListTile(
            key: const ValueKey('alerts-enabled'),
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.alertsEnable),
            value: config.enabled,
            onChanged: (v) => onChanged(config.copyWith(enabled: v)),
          ),
        ),
        if (config.enabled) ...[
          const SizedBox(height: 16),
          _LimitCard(
            switchKey: const ValueKey('alerts-wait'),
            label: l10n.alertsWaitLimit,
            value: config.maxWaitMin,
            range: AlertsConfig.waitRange,
            initial: 30,
            format: (v) => l10n.alertsMinutes(v),
            onChanged: (v) => onChanged(config.copyWith(maxWaitMin: () => v)),
          ),
          const SizedBox(height: 12),
          _LimitCard(
            switchKey: const ValueKey('alerts-noshow'),
            label: l10n.alertsNoShowLimit,
            value: config.maxNoShowPct,
            range: AlertsConfig.noShowRange,
            initial: 30,
            format: (v) => l10n.alertsPercent(v),
            onChanged: (v) => onChanged(config.copyWith(maxNoShowPct: () => v)),
          ),
          const SizedBox(height: 12),
          _LimitCard(
            switchKey: const ValueKey('alerts-idle'),
            label: l10n.alertsIdleLimit,
            value: config.idleMin,
            range: AlertsConfig.idleRange,
            initial: 15,
            format: (v) => l10n.alertsMinutes(v),
            onChanged: (v) => onChanged(config.copyWith(idleMin: () => v)),
          ),
          const SizedBox(height: 12),
          QioCard(child: _cooldown(context, l10n, config, onChanged)),
          if (config.activeRules == 0) ...[
            const SizedBox(height: 12),
            Text(
              l10n.alertsNoRule,
              key: const ValueKey('alerts-no-rule'),
              style: context.qioText.caption,
            ),
          ],
        ],
      ],
    );
  }
}

Widget _cooldown(
  BuildContext context,
  AppLocalizations l10n,
  AlertsConfig config,
  ValueChanged<AlertsConfig> onChanged,
) {
  final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.5;
  final dropdown = DropdownButton<int>(
    key: const ValueKey('alerts-cooldown'),
    isExpanded: stacked,
    value: AlertsConfig.cooldownOptions.contains(config.cooldownMin)
        ? config.cooldownMin
        : AlertsConfig.defaultCooldownMin,
    items: [
      for (final m in AlertsConfig.cooldownOptions)
        DropdownMenuItem(value: m, child: Text(l10n.alertsMinutes(m))),
    ],
    onChanged: (v) {
      if (v != null) onChanged(config.copyWith(cooldownMin: v));
    },
  );
  final label = Text(l10n.alertsCooldown);
  if (stacked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [label, dropdown],
    );
  }
  return Row(
    children: [
      Expanded(child: label),
      dropdown,
    ],
  );
}

class _LimitCard extends StatelessWidget {
  const _LimitCard({
    required this.switchKey,
    required this.label,
    required this.value,
    required this.range,
    required this.initial,
    required this.format,
    required this.onChanged,
  });

  final Key switchKey;
  final String label;
  final int? value;
  final (int, int) range;
  final int initial;
  final String Function(int) format;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final v = value;
    return QioCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            key: switchKey,
            contentPadding: EdgeInsets.zero,
            title: Text(label),
            subtitle: v != null ? Text(format(v)) : null,
            value: v != null,
            onChanged: (on) => onChanged(on ? initial : null),
          ),
          if (v != null)
            Slider(
              value: v.toDouble().clamp(
                range.$1.toDouble(),
                range.$2.toDouble(),
              ),
              min: range.$1.toDouble(),
              max: range.$2.toDouble(),
              divisions: range.$2 - range.$1,
              label: format(v),
              onChanged: (d) => onChanged(d.round()),
            ),
        ],
      ),
    );
  }
}
