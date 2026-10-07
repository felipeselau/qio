import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/account_format.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/haptics.dart';
import '../services/push_service.dart';
import '../services/locale_controller.dart';
import '../services/theme_controller.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/qio_avatar.dart';
import '../widgets/qio_button.dart';
import '../widgets/qio_card.dart';
import '../widgets/qio_skeleton.dart';
import '../widgets/qio_responsive_body.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({
    super.key,
    this.auth,
    this.loadOwner,
    this.loadQueueCount,
  });

  final AuthService? auth;
  @visibleForTesting
  final Future<Map<String, dynamic>?> Function(String uid)? loadOwner;
  @visibleForTesting
  final Future<int?> Function(String uid)? loadQueueCount;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  late final AuthService _auth = widget.auth ?? AuthService.instance;
  late final _user = _auth.currentUser;
  late final Future<Map<String, dynamic>?> _ownerFuture = _loadOwner();
  late final Future<int?> _countFuture = _loadCount();
  bool _signingOut = false;

  Future<Map<String, dynamic>?> _loadOwner() async {
    final uid = _user?.uid;
    if (uid == null) return null;
    try {
      final custom = widget.loadOwner;
      if (custom != null) return await custom(uid);
      final snap = await FirebaseFirestore.instance
          .collection('owners')
          .doc(uid)
          .get();
      return snap.data();
    } catch (_) {
      return null;
    }
  }

  Future<int?> _loadCount() async {
    final uid = _user?.uid;
    if (uid == null) return null;
    try {
      final custom = widget.loadQueueCount;
      if (custom != null) return await custom(uid);
      final agg = await FirebaseFirestore.instance
          .collection('queues')
          .where('ownerId', isEqualTo: uid)
          .count()
          .get();
      return agg.count;
    } catch (_) {
      return null;
    }
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;
      setState(() => _signingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).signOutError)),
      );
    }
  }

  String _displayName(Map<String, dynamic>? owner) {
    final ownerName = (owner?['name'] as String?)?.trim() ?? '';
    if (ownerName.isNotEmpty) return ownerName;
    final display = _user?.displayName?.trim() ?? '';
    if (display.isNotEmpty) return display;
    return _user?.email ?? '';
  }

  DateTime? _memberSince(Map<String, dynamic>? owner) {
    final created = owner?['createdAt'];
    if (created is Timestamp) return created.toDate();
    return _user?.metadata.creationTime;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: QioColors.gray100,
      appBar: AppBar(
        backgroundColor: QioColors.surface,
        title: Text(
          l10n.accountTitle,
          style: QioTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: QioColors.textPrimary,
          ),
        ),
      ),
      body: QioResponsiveBody(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _ownerFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const QioSkeletonList(count: 3);
            }
            return _buildContent(snap.data);
          },
        ),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic>? owner) {
    final l10n = AppLocalizations.of(context);
    final name = _displayName(owner);
    final business = (owner?['businessName'] as String?)?.trim() ?? '';
    final since = _memberSince(owner);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        QioCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              QioAvatar(name: name, size: 80),
              const SizedBox(height: 16),
              Text(
                name,
                textAlign: TextAlign.center,
                style: QioTextStyles.heading2.copyWith(
                  color: QioColors.textPrimary,
                ),
              ),
              if (business.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.businessLine(business),
                  textAlign: TextAlign.center,
                  style: QioTextStyles.body.copyWith(
                    color: QioColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Text(
                _user?.email ?? '',
                textAlign: TextAlign.center,
                style: QioTextStyles.body.copyWith(
                  color: QioColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        QioCard(
          child: Column(
            children: [
              FutureBuilder<int?>(
                future: _countFuture,
                builder: (context, snap) {
                  final String value;
                  if (snap.connectionState != ConnectionState.done) {
                    value = '...';
                  } else {
                    value = snap.data?.toString() ?? '—';
                  }
                  return _statRow(l10n.queuesCreated, value);
                },
              ),
              const Divider(height: 24),
              _statRow(
                l10n.memberSince,
                since == null ? '—' : formatMemberSince(since),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const _ThemeCard(),
        const SizedBox(height: 12),
        const _LanguageCard(),
        if (!kIsWeb) ...[
          const SizedBox(height: 12),
          const _HapticsCard(),
          if (AnalyticsController.instance.available) ...[
            const SizedBox(height: 12),
            const _AnalyticsCard(),
          ],
        ],
        const SizedBox(height: 24),
        QioButton(
          label: l10n.signOut,
          variant: QioButtonVariant.danger,
          isFullWidth: true,
          isLoading: _signingOut,
          onPressed: _signingOut ? null : _signOut,
        ),
      ],
    );
  }

  Widget _statRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: QioTextStyles.body.copyWith(color: QioColors.textSecondary),
        ),
        Text(
          value,
          style: QioTextStyles.bodyMedium.copyWith(
            color: QioColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = ThemeController.instance;
    return QioCard(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.appearance, style: QioTextStyles.bodyMedium),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l10n.systemOption),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l10n.themeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l10n.themeDark),
                  ),
                ],
                selected: {controller.mode},
                onSelectionChanged: (s) => controller.setMode(s.first),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = LocaleController.instance;
    final options = <(String?, String)>[
      (null, l10n.systemOption),
      ('pt', l10n.languagePortuguese),
      ('en', l10n.languageEnglish),
      ('es', l10n.languageSpanish),
    ];
    return QioCard(
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.languageTitle, style: QioTextStyles.bodyMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (code, label) in options)
                  ChoiceChip(
                    label: Text(label),
                    selected: controller.locale?.languageCode == code,
                    onSelected: (_) => controller.setLocale(
                      code == null ? null : Locale(code),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HapticsCard extends StatelessWidget {
  const _HapticsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return QioCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListenableBuilder(
        listenable: Haptics.instance,
        builder: (context, _) => SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Text(l10n.hapticsTitle, style: QioTextStyles.bodyMedium),
          subtitle: Text(l10n.hapticsSubtitle, style: QioTextStyles.caption),
          value: Haptics.instance.enabled,
          onChanged: Haptics.instance.setEnabled,
        ),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = AnalyticsController.instance;
    return QioCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          title: Text(l10n.analyticsTitle, style: QioTextStyles.bodyMedium),
          subtitle: Text(l10n.analyticsSubtitle, style: QioTextStyles.caption),
          value: !controller.optedOut,
          onChanged: (v) => controller.setOptOut(!v),
        ),
      ),
    );
  }
}

class _PushCard extends StatefulWidget {
  const _PushCard();

  @override
  State<_PushCard> createState() => _PushCardState();
}

class _PushCardState extends State<_PushCard> {
  bool? _enabled;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    PushService.instance.isEnabled().then((v) {
      if (mounted) setState(() => _enabled = v);
    });
  }

  Future<void> _toggle(bool value) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      if (value) {
        final granted = await PushService.instance.enable();
        if (!granted && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.pushDenied)));
        }
        if (mounted) setState(() => _enabled = granted);
      } else {
        await PushService.instance.disable();
        if (mounted) setState(() => _enabled = false);
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.genericActionError)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return QioCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        title: Text(l10n.pushTitle, style: QioTextStyles.bodyMedium),
        subtitle: Text(l10n.pushSubtitle, style: QioTextStyles.caption),
        value: _enabled ?? false,
        onChanged: _enabled == null || _busy ? null : _toggle,
      ),
    );
  }
}
