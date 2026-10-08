import 'dart:async';

import 'helpers/golden.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  installTolerantGoldenComparator();
  await testMain();
}
