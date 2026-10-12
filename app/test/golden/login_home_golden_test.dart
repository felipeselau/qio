@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/models/queue_group.dart';
import 'package:qio_app/screens/home_screen.dart';
import 'package:qio_app/screens/login_screen.dart';

import '../helpers/fake_auth.dart';
import '../helpers/fake_collapse_store.dart';
import '../helpers/fake_services.dart';
import '../helpers/golden.dart';

HomeScreen home() => HomeScreen(
  auth: FakeAuthService(user: FakeUser(displayName: 'Maria')),
  queues: FakeQueueService(
    ownerQueues: [
      fakeQueue('a', name: 'Padaria'),
      fakeQueue('b', name: 'Clinica', status: QueueStatus.paused),
      fakeQueue('c', name: 'Banco', status: QueueStatus.closed),
    ],
    waitingCounts: {'a': 3, 'b': 1, 'c': 0},
  ),
  operators: FakeOperatorService(),
  enableIntegrations: false,
);

HomeScreen groupedHome() => HomeScreen(
  auth: FakeAuthService(user: FakeUser(displayName: 'Maria')),
  queues: FakeQueueService(
    ownerQueues: [
      fakeQueue('a', name: 'Caixa 1', groupId: 'g1'),
      fakeQueue(
        'b',
        name: 'Caixa 2',
        groupId: 'g1',
        status: QueueStatus.paused,
      ),
      fakeQueue('c', name: 'Balcao', groupId: 'g2'),
      fakeQueue('d', name: 'Recepcao'),
    ],
    waitingCounts: {'a': 5, 'b': 3, 'c': 2, 'd': 1},
  ),
  operators: FakeOperatorService(),
  groups: FakeGroupService(
    groups: [
      QueueGroup(id: 'g1', name: 'Loja Centro', createdAt: DateTime(2025)),
      QueueGroup(id: 'g2', name: 'Anexo', createdAt: DateTime(2025)),
    ],
  ),
  collapseStore: MemoryCollapseStore({'g2'}),
  enableIntegrations: false,
);

void main() {
  const login390 = Size(390, 640);
  const login320 = Size(320, 560);
  const homeSize = Size(390, 640);

  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    final tag = mode.name;

    testWidgets('login 390 $tag', (tester) async {
      await goldenApp(
        tester,
        LoginScreen(auth: FakeAuthService()),
        'login_390_$tag',
        themeMode: mode,
        size: login390,
      );
    });

    testWidgets('login 320 $tag', (tester) async {
      await goldenApp(
        tester,
        LoginScreen(auth: FakeAuthService()),
        'login_320_$tag',
        themeMode: mode,
        size: login320,
      );
    });

    testWidgets('home 390 $tag', (tester) async {
      await goldenApp(
        tester,
        home(),
        'home_390_$tag',
        themeMode: mode,
        size: homeSize,
      );
    });

    testWidgets('home grouped 390 $tag', (tester) async {
      await goldenApp(
        tester,
        groupedHome(),
        'home_grouped_390_$tag',
        themeMode: mode,
        size: const Size(390, 760),
      );
    });
  }
}
