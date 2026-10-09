import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'fake_auth.dart';

class FakeSnapshot implements DataSnapshot {
  FakeSnapshot(this.value);

  @override
  final Object? value;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDatabaseRef implements DatabaseReference {
  FakeDatabaseRef(this.db, this.path);

  final FakeDatabase db;
  @override
  final String path;

  @override
  Future<void> set(Object? value, {Object? priority}) async {
    db.writes.add('set:$path');
    db.values[path] = value;
  }

  @override
  Future<void> update(Map<String, Object?> value) async {
    db.writes.add('update:$path');
  }

  @override
  Future<DataSnapshot> get() async {
    db.reads.add(path);
    return FakeSnapshot(db.values[path]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeDatabase implements FirebaseDatabase {
  final Map<String, Object?> values = {};
  final List<String> writes = [];
  final List<String> reads = [];

  bool get touched => writes.isNotEmpty || reads.isNotEmpty;

  @override
  DatabaseReference ref([String? path]) => FakeDatabaseRef(this, path ?? '');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirebaseAuth implements FirebaseAuth {
  FakeFirebaseAuth([String uid = 'uid-1']) : currentUser = FakeUser(uid: uid);

  @override
  final User? currentUser;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
