import 'package:firebase_core/firebase_core.dart';

import '../l10n/app_localizations.dart';

enum ActionError { offline, accessEnded, conflict, generic }

ActionError describeActionError(Object e) {
  if (e is FirebaseException) {
    switch (e.code) {
      case 'unavailable':
      case 'network-request-failed':
      case 'network-error':
      case 'disconnected':
      case 'deadline-exceeded':
        return ActionError.offline;
      case 'permission-denied':
      case 'unauthenticated':
        return ActionError.accessEnded;
      case 'aborted':
      case 'failed-precondition':
        return ActionError.conflict;
    }
  }
  return ActionError.generic;
}

extension ActionErrorMessage on ActionError {
  String message(AppLocalizations l10n) => switch (this) {
    ActionError.offline => l10n.actionErrorOffline,
    ActionError.accessEnded => l10n.actionErrorAccessEnded,
    ActionError.conflict => l10n.actionErrorConflict,
    ActionError.generic => l10n.genericActionError,
  };
}
