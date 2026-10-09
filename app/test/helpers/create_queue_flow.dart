import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/screens/create_queue_screen.dart';
import 'package:qio_app/services/create_queue_draft_store.dart';

import 'fake_services.dart';
import 'pump_app.dart';

Finder byKeyName(String key) => find.byKey(ValueKey(key));

Future<FakeQueueService> pumpCreate(
  WidgetTester tester, {
  FakeQueueService? queues,
  Size size = const Size(390, 844),
  CreateQueueDraftStore? draftStore,
  String? uid,
  FakeGroupService? groups,
  double textScale = 1,
}) async {
  final service = queues ?? FakeQueueService();
  Widget home = CreateQueueScreen(
    queues: service,
    groups: groups ?? FakeGroupService(),
    draftStore: draftStore,
    uid: uid,
  );
  if (textScale != 1) {
    final screen = home;
    home = Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: screen,
      ),
    );
  }
  await pumpApp(tester, home, size: size);
  await tester.pumpAndSettle();
  return service;
}

Future<void> tapKey(WidgetTester tester, String key) =>
    tapFinder(tester, byKeyName(key));

Future<void> tapFinder(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> enterKey(WidgetTester tester, String key, String text) async {
  await tester.enterText(byKeyName(key), text);
  await tester.pump();
}

Future<void> typeName(WidgetTester tester, String name) async {
  await enterKey(tester, 'create-name', name);
}

Future<void> continueSteps(WidgetTester tester, int times) async {
  for (var i = 0; i < times; i++) {
    await tapKey(tester, 'create-continue');
  }
}

Future<void> goToReview(WidgetTester tester, {String name = 'Clínica'}) async {
  await typeName(tester, name);
  await continueSteps(tester, 5);
}

String textOf(WidgetTester tester, String key) => tester
    .widget<EditableText>(
      find.descendant(of: byKeyName(key), matching: find.byType(EditableText)),
    )
    .controller
    .text;
