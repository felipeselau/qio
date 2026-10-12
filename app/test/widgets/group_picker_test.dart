import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/models/queue_group.dart';
import 'package:qio_app/widgets/group_picker.dart';

import '../helpers/fake_services.dart';
import '../helpers/pump_app.dart';

void main() {
  testWidgets('rebuilds e textScale mantêm uma única assinatura', (
    tester,
  ) async {
    final groups = FakeGroupService(
      groups: [
        QueueGroup(id: 'g1', name: 'Loja Centro', createdAt: DateTime(2025)),
      ],
    );
    late StateSetter rebuild;
    var scale = 1.0;
    String? value;
    await pumpApp(
      tester,
      Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: GroupPicker(
                groups: groups,
                value: value,
                onChanged: (v) => setState(() => value = v),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(groups.watchCalls, 1);

    rebuild(() => scale = 2);
    await tester.pumpAndSettle();
    rebuild(() => value = 'g1');
    await tester.pumpAndSettle();
    rebuild(() {});
    await tester.pump();

    expect(groups.watchCalls, 1);
    expect(find.text('Loja Centro'), findsOneWidget);
  });

  testWidgets('trocar o serviço reabre a assinatura', (tester) async {
    final a = FakeGroupService();
    final b = FakeGroupService();
    late StateSetter rebuild;
    var current = a;
    await pumpApp(
      tester,
      Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return GroupPicker(groups: current, value: null, onChanged: (_) {});
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    rebuild(() => current = b);
    await tester.pumpAndSettle();
    expect(a.watchCalls, 1);
    expect(b.watchCalls, 1);
  });
}
