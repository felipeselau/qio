import 'dart:async';

import 'package:firebase_core/firebase_core.dart';

const permissionRetryDelay = Duration(milliseconds: 2500);
const permissionRetryMax = 5;

bool isPermissionDenied(Object error) =>
    error is FirebaseException && error.code == 'permission-denied';

Stream<T> retryOnPermissionDenied<T>(
  Stream<T> Function() open, {
  Duration delay = permissionRetryDelay,
  int maxAttempts = permissionRetryMax,
}) {
  late StreamController<T> controller;
  StreamSubscription<T>? sub;
  Timer? timer;
  var failures = 0;

  void attach() {
    sub = open().listen(
      (value) {
        failures = 0;
        controller.add(value);
      },
      onError: (Object error, StackTrace stack) {
        if (isPermissionDenied(error) && failures < maxAttempts) {
          failures++;
          sub?.cancel();
          sub = null;
          timer = Timer(delay, () {
            if (!controller.isClosed) attach();
          });
          return;
        }
        controller.addError(error, stack);
      },
      onDone: () {
        if (timer == null || !timer!.isActive) controller.close();
      },
    );
  }

  controller = StreamController<T>(
    onListen: attach,
    onCancel: () async {
      timer?.cancel();
      await sub?.cancel();
    },
  );
  return controller.stream;
}
