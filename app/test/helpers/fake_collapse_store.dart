import 'package:qio_app/services/home_grouping.dart';

class MemoryCollapseStore implements GroupCollapseStore {
  MemoryCollapseStore([Set<String>? initial]) : saved = {...?initial};

  Set<String> saved;
  int saves = 0;

  @override
  Future<Set<String>> load(String uid) async => {...saved};

  @override
  Future<void> save(String uid, Set<String> collapsed) async {
    saved = {...collapsed};
    saves++;
  }
}
