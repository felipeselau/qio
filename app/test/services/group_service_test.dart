import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/services/group_service.dart';

import '../helpers/fake_rtdb.dart';

void main() {
  late FakeFirebaseFirestore fs;
  late GroupService svc;

  setUp(() {
    fs = FakeFirebaseFirestore();
    svc = GroupService.forTesting(fs, FakeFirebaseAuth());
  });

  CollectionReference<Map<String, dynamic>> groups() =>
      fs.collection('owners').doc('uid-1').collection('groups');

  Future<void> seed(String id, String name, {int? order, String? color}) =>
      groups().doc(id).set({
        'name': name,
        'createdAt': Timestamp.fromDate(DateTime(2026)),
        'order': ?order,
        'colorHex': ?color,
      });

  test('reorderGroups grava order pela posição', () async {
    await seed('a', 'A');
    await seed('b', 'B');
    await seed('c', 'C');
    await svc.reorderGroups(['c', 'a', 'b']);
    expect((await groups().doc('c').get()).data()!['order'], 0);
    expect((await groups().doc('a').get()).data()!['order'], 1);
    expect((await groups().doc('b').get()).data()!['order'], 2);
    final listed = await svc.fetchGroups();
    expect(listed.map((g) => g.id), ['c', 'a', 'b']);
  });

  test('updateGroupColor grava e remove a cor', () async {
    await seed('a', 'A');
    await svc.updateGroupColor('a', '#2563EB');
    expect((await groups().doc('a').get()).data()!['colorHex'], '#2563EB');
    expect((await svc.fetchGroups()).single.colorHex, '#2563EB');
    await svc.updateGroupColor('a', null);
    final data = (await groups().doc('a').get()).data()!;
    expect(data.containsKey('colorHex'), isFalse);
  });

  test('doc legado sem order segue ordenado por nome', () async {
    await seed('b', 'Beta');
    await seed('a', 'Alfa');
    expect((await svc.fetchGroups()).map((g) => g.id), ['a', 'b']);
  });
}
