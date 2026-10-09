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
import '../widgets/queue_form/alerts_form.dart';
import '../theme/qio_palette.dart';

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
  bool _notify = true;

  @override
  void initState() {
    super.initState();
    _checkPush();
    _loadNotify();
  }

  Future<void> _loadNotify() async {
    try {
      final v = await PushService.instance.alertsEnabled();
      if (mounted) setState(() => _notify = v);
    } on Exception {
      return;
    }
  }

  Future<void> _toggleNotify(bool v) async {
    final previous = _notify;
    setState(() => _notify = v);
    try {
      await PushService.instance.setAlertsEnabled(v);
    } on Exception {
      if (mounted) setState(() => _notify = previous);
    }
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
        backgroundColor: context.qio.surface,
        title: Text(
          l10n.alertsTitle,
          style: context.qioText.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: context.qio.textPrimary,
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
                        style: context.qioText.caption,
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
                title: Text(l10n.alertsNotify),
                value: _notify,
                onChanged: _toggleNotify,
              ),
            ),
            const SizedBox(height: 12),
            AlertsForm(
              value: _config,
              onChanged: (v) => setState(() => _config = v),
            ),
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
