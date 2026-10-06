import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_entry.dart';
import 'package:qio_app/widgets/queue_panel/animated_entry_list.dart';

QueueEntry entry(String id, int ticket) => QueueEntry(
  id: id,
  ticket: ticket,
  name: 'P$ticket',
  uid: 'u$ticket',
  status: EntryStatus.waiting,
  joinedAt: DateTime(2026, 10, 1),
);

Widget host(List<QueueEntry> entries) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: AnimatedEntryList(
        entries: entries,
        itemBuilder: (context, e) => Text('item-${e.id}'),
      ),
    ),
  ),
);

void main() {
  testWidgets('renders the initial entries', (tester) async {
    await tester.pumpWidget(host([entry('a', 1), entry('b', 2)]));
    expect(find.text('item-a'), findsOneWidget);
    expect(find.text('item-b'), findsOneWidget);
  });

  testWidgets('animates in new entries and removes departed ones', (
    tester,
  ) async {
    await tester.pumpWidget(host([entry('a', 1), entry('b', 2)]));
    await tester.pumpWidget(
      host([entry('a', 1), entry('b', 2), entry('c', 3)]),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('item-c'), findsOneWidget);
    await tester.pumpAndSettle();
    await tester.pumpWidget(host([entry('b', 2), entry('c', 3)]));
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('item-a'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('item-a'), findsNothing);
    expect(find.text('item-b'), findsOneWidget);
    expect(find.text('item-c'), findsOneWidget);
  });

  testWidgets('handles an empty list and later arrivals', (tester) async {
    await tester.pumpWidget(host(const []));
    await tester.pumpWidget(host([entry('x', 1)]));
    await tester.pumpAndSettle();
    expect(find.text('item-x'), findsOneWidget);
  });
}
