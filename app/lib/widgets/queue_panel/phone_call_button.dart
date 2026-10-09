import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';
import '../../services/phone_call.dart';
import '../../theme/qio_palette.dart';

Future<bool> _defaultLauncher(Uri uri) => launchUrl(uri);

class PhoneCallButton extends StatelessWidget {
  const PhoneCallButton({
    super.key,
    required this.phone,
    required this.name,
    this.launcher,
    this.color,
  });

  final String? phone;
  final String name;
  final UrlLauncher? launcher;
  final Color? color;

  Future<void> _call(BuildContext context, Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    final message = AppLocalizations.of(context).callPhoneFailed;
    var ok = false;
    try {
      ok = await (launcher ?? _defaultLauncher)(uri);
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uri = phoneToTelUri(phone);
    if (uri == null) return const SizedBox.shrink();
    final tooltip = AppLocalizations.of(context).callPhoneTooltip(name);
    return IconButton(
      icon: const Icon(Icons.phone_outlined),
      color: color ?? context.qio.primaryText,
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      onPressed: () => _call(context, uri),
    );
  }
}
