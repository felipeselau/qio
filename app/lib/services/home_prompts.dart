import 'dart:async';

class HomePrompts {
  HomePrompts({
    required this.runTour,
    required this.shouldPromptPush,
    required this.askPush,
    required this.canShowDialog,
    this.tourTimeout = const Duration(minutes: 5),
  });

  final Future<void> Function() runTour;
  final Future<bool> Function() shouldPromptPush;
  final Future<void> Function() askPush;
  final bool Function() canShowDialog;
  final Duration tourTimeout;

  bool _tourDone = false;
  bool _running = false;
  bool _pushHandled = false;

  bool get tourDone => _tourDone;

  Future<void> onQueues({
    required bool hasOwned,
    bool Function()? routeFree,
  }) async {
    bool free() => (routeFree?.call() ?? true) && canShowDialog();
    if (_running) return;
    _running = true;
    try {
      if (!_tourDone) {
        if (!free()) return;
        await Future.sync(runTour).timeout(tourTimeout).catchError((_) {});
        _tourDone = true;
      }
      if (_pushHandled || !hasOwned) return;
      if (!free()) return;
      if (!await shouldPromptPush()) {
        _pushHandled = true;
        return;
      }
      if (!free()) return;
      _pushHandled = true;
      await askPush();
    } finally {
      _running = false;
    }
  }
}
