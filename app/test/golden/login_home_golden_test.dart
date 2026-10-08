@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue.dart';
import 'package:qio_app/screens/home_screen.dart';
import 'package:qio_app/screens/login_screen.dart';

import '../helpers/fake_auth.dart';
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
  }
}
