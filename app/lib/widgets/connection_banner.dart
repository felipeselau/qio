import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/qio_text_styles.dart';
import '../theme/qio_palette.dart';

class ConnectionBanner extends StatefulWidget {
  const ConnectionBanner({
    super.key,
    required this.connected,
    required this.child,
    this.delay = const Duration(seconds: 3),
  });

  final Stream<bool> connected;
  final Widget child;
  final Duration delay;

  @override
  State<ConnectionBanner> createState() => _ConnectionBannerState();
}

class _ConnectionBannerState extends State<ConnectionBanner> {
  StreamSubscription<bool>? _sub;
  Timer? _timer;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    _sub = widget.connected.listen(_onChanged, onError: (_) {});
  }

  void _onChanged(bool connected) {
    _timer?.cancel();
    if (connected) {
      if (_offline && mounted) setState(() => _offline = false);
      return;
    }
    _timer = Timer(widget.delay, () {
      if (mounted) setState(() => _offline = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bar = AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: _offline
          ? Semantics(
              liveRegion: true,
              child: Material(
                color: context.qio.statusPausedText,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cloud_off_outlined,
                          size: 18,
                          color: context.qio.background,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.offlineBanner,
                            style: context.qioText.caption.copyWith(
                              color: context.qio.background,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
    return Column(
      children: [
        bar,
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: _offline,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
