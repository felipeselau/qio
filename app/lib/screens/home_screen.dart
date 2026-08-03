import 'package:flutter/material.dart';

import '../models/queue.dart';
import '../services/auth_service.dart';
import '../services/queue_service.dart';
import '../theme/qio_colors.dart';
import '../theme/qio_text_styles.dart';
import '../widgets/qio_avatar.dart';
import '../widgets/qio_badge.dart';
import '../widgets/qio_card.dart';
import 'create_queue_screen.dart';
import 'login_screen.dart';
import 'queue_panel_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;
    return Scaffold(
      backgroundColor: QioColors.gray100,
      appBar: AppBar(
        backgroundColor: QioColors.surface,
        title: Text(
          'Minhas filas',
          style: QioTextStyles.heading2.copyWith(
            fontWeight: FontWeight.w700,
            color: QioColors.textPrimary,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () async {
                await AuthService.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                }
              },
              child: QioAvatar(
                name: user?.displayName ?? user?.email ?? 'Q',
                size: 36,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<Queue>>(
        stream: QueueService.instance.watchOwnerQueues(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final queues = snapshot.data ?? [];
          if (queues.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_2, size: 64, color: QioColors.gray300),
                    const SizedBox(height: 16),
                    Text('Nenhuma fila ainda', style: QioTextStyles.heading2),
                    const SizedBox(height: 8),
                    Text(
                      'Crie sua primeira fila e comece a atender',
                      style: QioTextStyles.body.copyWith(
                        color: QioColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: queues.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, i) {
              final q = queues[i];
              return QioCard(
                padding: const EdgeInsets.all(20),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        QueuePanelScreen(queueId: q.id, queueName: q.name),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            q.name,
                            style: QioTextStyles.heading3.copyWith(
                              fontWeight: FontWeight.w600,
                              color: QioColors.textPrimary,
                            ),
                          ),
                        ),
                        QioBadge(
                          label: q.status.label,
                          status: switch (q.status) {
                            QueueStatus.open => QioBadgeStatus.open,
                            QueueStatus.paused => QioBadgeStatus.paused,
                            QueueStatus.closed => QioBadgeStatus.closed,
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<int>(
                      stream: QueueService.instance.watchWaitingCount(q.id),
                      builder: (context, snap) {
                        final count = snap.data ?? 0;
                        return Text(
                          '$count ${count == 1 ? "pessoa" : "pessoas"} esperando',
                          style: QioTextStyles.body.copyWith(
                            fontSize: 14,
                            color: QioColors.gray700,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Criada em ${q.createdAt.day.toString().padLeft(2, '0')}/${q.createdAt.month.toString().padLeft(2, '0')}/${q.createdAt.year}',
                      style: QioTextStyles.caption.copyWith(
                        fontSize: 12,
                        color: QioColors.gray400,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const CreateQueueScreen())),
        child: const Icon(Icons.add),
      ),
    );
  }
}
