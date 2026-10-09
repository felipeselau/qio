import 'dart:async';

import '../models/queue_entry.dart';

int countWaitingPublic(Object? value) {
  if (value is! Map) return 0;
  return value.values
      .where((v) => v is Map && v['status'] == EntryStatus.waiting.value)
      .length;
}

Stream<int> waitingCountStream({
  required Stream<Object?> metaCount,
  required Stream<Object?> Function() publicNode,
}) {
  late final StreamController<int> controller;
  StreamSubscription<Object?>? metaSub;
  StreamSubscription<Object?>? fallbackSub;

  void stopFallback() {
    fallbackSub?.cancel();
    fallbackSub = null;
  }

  controller = StreamController<int>(
    onListen: () {
      metaSub = metaCount.listen((value) {
        if (value is num) {
          stopFallback();
          controller.add(value.toInt());
          return;
        }
        fallbackSub ??= publicNode().listen(
          (node) => controller.add(countWaitingPublic(node)),
          onError: controller.addError,
        );
      }, onError: controller.addError);
    },
    onCancel: () async {
      await metaSub?.cancel();
      stopFallback();
    },
  );
  return controller.stream;
}
