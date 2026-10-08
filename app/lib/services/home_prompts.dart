import 'dart:async';

class HomePrompts {
  HomePrompts({
    required this.runTour,
    required this.shouldPromptPush,
    required this.askPush,
    required this.canShowDialog,
  });

  final Future<void> Function() runTour;
  final Future<bool> Function() shouldPromptPush;
  final Future<void> Function() askPush;
  final bool Function() canShowDialog;

  bool _tourDone = false;
  bool _running = false;
  bool _pushHandled = false;

  bool get tourDone => _tourDone;

  Future<void> onQueues({required bool hasOwned}) async {
    if (_running) return;
    _running = true;
    try {
      if (!_tourDone) {
        _tourDone = true;
        await runTour();
      }
      if (_pushHandled || !hasOwned || !canShowDialog()) return;
      if (!await shouldPromptPush()) {
        _pushHandled = true;
        return;
      }
      if (!canShowDialog()) return;
      _pushHandled = true;
      await askPush();
    } finally {
      _running = false;
    }
  }
}
