import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/account_format.dart';
import '../services/auth_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/qio_avatar.dart';
import '../widgets/qio_button.dart';
import '../widgets/qio_card.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _user = AuthService.instance.currentUser;
  late final Future<Map<String, dynamic>?> _ownerFuture = _loadOwner();
  late final Future<int?> _countFuture = _loadCount();
  bool _signingOut = false;

  Future<Map<String, dynamic>?> _loadOwner() async {
    final uid = _user?.uid;
    if (uid == null) return null;
    try {
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
      await AuthService.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _signingOut = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível sair da conta.')),
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
    return Scaffold(
      backgroundColor: QioColors.gray100,
      appBar: AppBar(
        backgroundColor: QioColors.surface,
        title: Text(
          'Minha conta',
          style: QioTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: QioColors.textPrimary,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _ownerFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildContent(snap.data);
        },
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic>? owner) {
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
                  'Negócio: $business',
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
                  return _statRow('Filas criadas', value);
                },
              ),
              const Divider(height: 24),
              _statRow(
                'Membro desde',
                since == null ? '—' : formatMemberSince(since),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        QioButton(
          label: 'Sair da conta',
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
