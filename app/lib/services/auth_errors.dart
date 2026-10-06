import '../l10n/app_localizations.dart';

String authErrorMessage(AppLocalizations l10n, String code) {
  switch (code) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return l10n.authInvalidCredentials;
    case 'invalid-email':
      return l10n.authInvalidEmail;
    case 'email-already-in-use':
      return l10n.authEmailInUse;
    case 'weak-password':
      return l10n.authWeakPassword;
    case 'user-disabled':
      return l10n.authUserDisabled;
    case 'too-many-requests':
      return l10n.authTooManyRequests;
    case 'network-request-failed':
      return l10n.authNetworkError;
    default:
      return l10n.authGeneric;
  }
}
