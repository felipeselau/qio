import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/queue.dart';
import '../services/join_url.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_palette.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/qio_button.dart';
import '../widgets/qio_responsive_body.dart';
import 'alerts_settings_screen.dart';
import 'operators_screen.dart';
import 'queue_panel_screen.dart';
import 'queue_settings_screen.dart';

enum QueueCreatedTarget { panel, logo, shortLink, operators, alerts }

typedef QueueShare = Future<void> Function(String url);
typedef QueueCreatedDestination =
    Widget Function(BuildContext context, QueueCreatedTarget target);

Future<void> _sharePlus(String url) =>
    SharePlus.instance.share(ShareParams(text: url));

class QueueCreatedScreen extends StatelessWidget {
  const QueueCreatedScreen({
    super.key,
    required this.queue,
    this.queues,
    this.onShare,
    @visibleForTesting this.destinationBuilder,
  });

  final Queue queue;
  final QueueService? queues;
  final QueueShare? onShare;
  final QueueCreatedDestination? destinationBuilder;

  String get _link => joinUrl(queue.id);

  Widget _destination(BuildContext context, QueueCreatedTarget target) {
    final builder = destinationBuilder;
    if (builder != null) return builder(context, target);
    return switch (target) {
      QueueCreatedTarget.panel => QueuePanelScreen(
        queueId: queue.id,
        queueName: queue.name,
        queues: queues,
      ),
      QueueCreatedTarget.logo ||
      QueueCreatedTarget.shortLink => QueueSettingsScreen(
        queueId: queue.id,
        queueName: queue.name,
        isOwner: true,
        queues: queues,
      ),
      QueueCreatedTarget.operators => OperatorsScreen(queueId: queue.id),
      QueueCreatedTarget.alerts => AlertsSettingsScreen(
        queueId: queue.id,
        initial: queue.alerts,
      ),
    };
  }

  void _openPanel(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => _destination(context, QueueCreatedTarget.panel),
      ),
    );
  }

  void _open(BuildContext context, QueueCreatedTarget target) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _destination(context, target)),
    );
  }

  Future<void> _copy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: _link));
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.linkCopied),
        backgroundColor: QioColors.successStrong,
      ),
    );
  }

  Future<void> _share(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    try {
      await (onShare ?? _sharePlus)(_link);
    } on Exception {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.genericActionError),
          backgroundColor: QioColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _openPanel(context);
      },
      child: Scaffold(
        backgroundColor: context.qio.surface,
        body: SafeArea(
          child: QioResponsiveBody(
            maxWidth: 520,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                Semantics(
                  header: true,
                  liveRegion: true,
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 56,
                        color: QioColors.successStrong,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.cqCreatedTitle,
                        key: const ValueKey('created-title'),
                        textAlign: TextAlign.center,
                        style: context.qioText.heading2.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.qio.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  queue.name,
                  key: const ValueKey('created-name'),
                  textAlign: TextAlign.center,
                  style: context.qioText.bodyMedium.copyWith(
                    color: context.qio.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.cqCreatedHint,
                  textAlign: TextAlign.center,
                  style: context.qioText.caption,
                ),
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.qio.gray200),
                    ),
                    child: Semantics(
                      image: true,
                      label: l10n.qrSemantics,
                      child: QrImageView(
                        key: const ValueKey('created-qr'),
                        data: _link,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  button: true,
                  label: l10n.copyLinkSemantics,
                  excludeSemantics: true,
                  child: InkWell(
                    key: const ValueKey('created-link'),
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _copy(context),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: context.qio.gray100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _link.replaceFirst('https://', ''),
                              style: context.qioText.caption.copyWith(
                                fontSize: 13,
                                color: context.qio.gray700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.copy,
                            size: 16,
                            color: QioColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                QioButton(
                  key: const ValueKey('created-share'),
                  label: l10n.cqShareLink,
                  icon: Icons.share_outlined,
                  isFullWidth: true,
                  onPressed: () => _share(context),
                ),
                const SizedBox(height: 12),
                QioButton(
                  key: const ValueKey('created-open-panel'),
                  label: l10n.cqOpenPanel,
                  variant: QioButtonVariant.secondary,
                  icon: Icons.dashboard_outlined,
                  isFullWidth: true,
                  onPressed: () => _openPanel(context),
                ),
                const SizedBox(height: 28),
                Semantics(
                  header: true,
                  child: Text(l10n.cqPolishTitle, style: context.qioText.label),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _shortcut(
                      context,
                      'created-shortcut-logo',
                      Icons.palette_outlined,
                      l10n.cqShortcutLogo,
                      QueueCreatedTarget.logo,
                    ),
                    _shortcut(
                      context,
                      'created-shortcut-link',
                      Icons.link,
                      l10n.cqShortcutShortLink,
                      QueueCreatedTarget.shortLink,
                    ),
                    _shortcut(
                      context,
                      'created-shortcut-operators',
                      Icons.groups_outlined,
                      l10n.cqShortcutOperators,
                      QueueCreatedTarget.operators,
                    ),
                    _shortcut(
                      context,
                      'created-shortcut-alerts',
                      Icons.notifications_active_outlined,
                      l10n.cqShortcutAlerts,
                      QueueCreatedTarget.alerts,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _shortcut(
    BuildContext context,
    String key,
    IconData icon,
    String label,
    QueueCreatedTarget target,
  ) {
    return ActionChip(
      key: ValueKey(key),
      avatar: Icon(icon, size: 18),
      label: Text(label),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      onPressed: () => _open(context, target),
    );
  }
}
