import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/queue_service.dart';
import '../../theme/qio_palette.dart';
import '../../theme/qio_text_styles.dart';
import '../qio_button.dart';
import '../qio_responsive_body.dart';
import '../queue_panel/panel_notices.dart';

class QueueLimitGate extends StatelessWidget {
  const QueueLimitGate({super.key, required this.checking});

  final bool checking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.qio.surface,
        leading: const QueueBackButton(key: ValueKey('create-back')),
        title: Text(
          l10n.newQueue,
          style: context.qioText.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: context.qio.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: QioResponsiveBody(
        maxWidth: 520,
        child: checking
            ? Center(
                child: Semantics(
                  liveRegion: true,
                  label: l10n.cqCheckingLimit,
                  child: const CircularProgressIndicator(
                    key: ValueKey('create-limit-checking'),
                  ),
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.block, size: 48, color: context.qio.gray500),
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        l10n.cqLimitTitle,
                        key: const ValueKey('create-limit-title'),
                        textAlign: TextAlign.center,
                        style: context.qioText.heading2.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.qio.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.queueLimitReached(maxQueuesPerOwner),
                      key: const ValueKey('create-limit-message'),
                      textAlign: TextAlign.center,
                      style: context.qioText.body,
                    ),
                    const SizedBox(height: 24),
                    QioButton(
                      key: const ValueKey('create-limit-back'),
                      label: l10n.back,
                      isFullWidth: true,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
