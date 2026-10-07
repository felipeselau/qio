import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/alerts_config.dart';
import '../services/push_service.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/qio_button.dart';
import '../widgets/qio_card.dart';
import '../widgets/qio_responsive_body.dart';

class AlertsSettingsScreen extends StatefulWidget {
  const AlertsSettingsScreen({
    super.key,
    required this.queueId,
    required this.initial,
  });

  final String queueId;
  final AlertsConfig? initial;

  @override
  State<AlertsSettingsScreen> createState() => _AlertsSettingsScreenState();
}

class _AlertsSettingsScreenState extends State<AlertsSettingsScreen> {
  late AlertsConfig _config = widget.initial ?? const AlertsConfig();
  bool _saving = false;
  bool _pushOff = false;

  @override
  void initState() {
    super.initState();
    _checkPush();
  }

  Future<void> _checkPush() async {
    if (!PushService.instance.supported) return;
    final granted = await PushService.instance.hasPermission();
    if (mounted) setState(() => _pushOff = !granted);
  }

  bool get _canSave => !_config.enabled || _config.activeRules > 0;

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await QueueService.instance.updateAlerts(widget.queueId, _config);
      if (mounted) navigator.pop();
    } on Exception {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.genericActionError),
          backgroundColor: QioColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: QioColors.surface,
        title: Text(
          l10n.alertsTitle,
          style: QioTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: QioColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: QioResponsiveBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_pushOff) ...[
              QioCard(
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      color: QioColors.error,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.alertsPushOff,
                        style: QioTextStyles.caption,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            QioCard(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.alertsEnable),
                value: _config.enabled,
                onChanged: (v) =>
                    setState(() => _config = _config.copyWith(enabled: v)),
              ),
            ),
            if (_config.enabled) ...[
              const SizedBox(height: 16),
              _LimitCard(
                label: l10n.alertsWaitLimit,
                value: _config.maxWaitMin,
                range: AlertsConfig.waitRange,
                initial: 30,
                format: (v) => l10n.alertsMinutes(v),
                onChanged: (v) => setState(
                  () => _config = _config.copyWith(maxWaitMin: () => v),
                ),
              ),
              const SizedBox(height: 12),
              _LimitCard(
                label: l10n.alertsNoShowLimit,
                value: _config.maxNoShowPct,
                range: AlertsConfig.noShowRange,
                initial: 30,
                format: (v) => l10n.alertsPercent(v),
                onChanged: (v) => setState(
                  () => _config = _config.copyWith(maxNoShowPct: () => v),
                ),
              ),
              const SizedBox(height: 12),
              _LimitCard(
                label: l10n.alertsIdleLimit,
                value: _config.idleMin,
                range: AlertsConfig.idleRange,
                initial: 15,
                format: (v) => l10n.alertsMinutes(v),
                onChanged: (v) => setState(
                  () => _config = _config.copyWith(idleMin: () => v),
                ),
              ),
              const SizedBox(height: 12),
              QioCard(
                child: Row(
                  children: [
                    Expanded(child: Text(l10n.alertsCooldown)),
                    DropdownButton<int>(
                      value:
                          AlertsConfig.cooldownOptions.contains(
                            _config.cooldownMin,
                          )
                          ? _config.cooldownMin
                          : AlertsConfig.defaultCooldownMin,
                      items: [
                        for (final m in AlertsConfig.cooldownOptions)
                          DropdownMenuItem(
                            value: m,
                            child: Text(l10n.alertsMinutes(m)),
                          ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          setState(
                            () => _config = _config.copyWith(cooldownMin: v),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              if (!_canSave) ...[
                const SizedBox(height: 12),
                Text(l10n.alertsNoRule, style: QioTextStyles.caption),
              ],
            ],
            const SizedBox(height: 24),
            QioButton(
              label: l10n.save,
              isFullWidth: true,
              isLoading: _saving,
              onPressed: _canSave && !_saving ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _LimitCard extends StatelessWidget {
  const _LimitCard({
    required this.label,
    required this.value,
    required this.range,
    required this.initial,
    required this.format,
    required this.onChanged,
  });

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
