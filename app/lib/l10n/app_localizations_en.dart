// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get back => 'Back';

  @override
  String get backWithArrow => '← Back';

  @override
  String get create => 'Create';

  @override
  String get remove => 'Remove';

  @override
  String get delete => 'Delete';

  @override
  String get copy => 'Copy';

  @override
  String get share => 'Share';

  @override
  String get print => 'Print';

  @override
  String get genericActionError =>
      'Couldn\'t complete the action. Please try again.';

  @override
  String get authInvalidCredentials => 'Incorrect email or password.';

  @override
  String get authInvalidEmail => 'Invalid email.';

  @override
  String get authEmailInUse => 'An account with this email already exists.';

  @override
  String get authWeakPassword => 'Weak password. Use at least 6 characters.';

  @override
  String get authUserDisabled => 'This account has been disabled.';

  @override
  String get authTooManyRequests =>
      'Too many attempts. Wait a few minutes and try again.';

  @override
  String get authNetworkError =>
      'No connection. Check your internet and try again.';

  @override
  String get authGeneric => 'Couldn\'t sign in. Please try again.';

  @override
  String get loginTagline => 'Smart queue management';

  @override
  String get nameLabel => 'Name';

  @override
  String get nameHint => 'Your name';

  @override
  String get nameRequired => 'Enter your name';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailHint => 'you@email.com';

  @override
  String get emailRequired => 'Enter your email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordMin => 'At least 6 characters';

  @override
  String get signIn => 'Sign in';

  @override
  String get createAccount => 'Create account';

  @override
  String get orSeparator => 'or';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get haveAccountSignIn => 'Already have an account? Sign in';

  @override
  String get accountTitle => 'My account';

  @override
  String businessLine(String business) {
    return 'Business: $business';
  }

  @override
  String get queuesCreated => 'Queues created';

  @override
  String get memberSince => 'Member since';

  @override
  String get signOut => 'Sign out';

  @override
  String get signOutError => 'Couldn\'t sign out.';

  @override
  String get appearance => 'Appearance';

  @override
  String get systemOption => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageTitle => 'Language';

  @override
  String get languagePortuguese => 'Português';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get newQueue => 'New queue';

  @override
  String get queueNameLabel => 'Queue name *';

  @override
  String get queueNameHint => 'E.g. Front desk';

  @override
  String get queueNameRequired => 'Enter the name';

  @override
  String get descriptionLabel => 'Description (optional)';

  @override
  String get descriptionHint => 'Describe the purpose of the queue...';

  @override
  String get avgServiceLabel => 'Average service time (minutes)';

  @override
  String get invalidNumber => 'Enter a valid number';

  @override
  String get createQueue => 'Create queue';

  @override
  String get myQueues => 'My queues';

  @override
  String get joinAsOperator => 'Join as operator';

  @override
  String get tourHomeFabTitle => 'Create your first queue';

  @override
  String get tourHomeFabBody =>
      'Tap + to create a queue and generate the QR code.';

  @override
  String get tourHomeQueueTitle => 'Open your queue';

  @override
  String get tourHomeQueueBody =>
      'Tap the card to see the QR code and call people.';

  @override
  String get tourHomeOperatorTitle => 'Join as operator';

  @override
  String get tourHomeOperatorBody =>
      'Got an invite code? Use it here to help run a queue.';

  @override
  String get emptyQueuesTitle => 'No queues yet';

  @override
  String get emptyQueuesBody =>
      'Create your first queue or join as an operator with an invite code';

  @override
  String get sectionOwner => 'I\'M THE OWNER';

  @override
  String get sectionOperator => 'I\'M AN OPERATOR';

  @override
  String get sectionRequests => 'OPERATOR REQUESTS';

  @override
  String waitingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people waiting',
      one: '$count person waiting',
    );
    return '$_temp0';
  }

  @override
  String createdOn(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMd(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Created on $dateString';
  }

  @override
  String get youAreOperator => 'You are an operator of this queue';

  @override
  String get requestRemovedStatus => 'You were removed from this queue';

  @override
  String get requestRejectedStatus => 'Request declined';

  @override
  String get awaitingApproval => 'Awaiting approval';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusClosed => 'Closed';

  @override
  String get joinOperatorIntro =>
      'Ask the queue owner for the invite code. After you send it, the owner must approve your access.';

  @override
  String get inviteCodeLabel => 'Invite code';

  @override
  String get inviteCodeHint => 'E.g. K7M2QX';

  @override
  String get inviteCodeLength => 'The code has 6 characters';

  @override
  String get sendRequest => 'Send request';

  @override
  String get sendRequestError =>
      'Couldn\'t send the request. Please try again.';

  @override
  String get cancelRequestError => 'Couldn\'t cancel. Please try again.';

  @override
  String get pendingBody =>
      'The queue owner needs to approve your request. This screen updates by itself.';

  @override
  String get requestApproved => 'Request approved';

  @override
  String get approvedBody => 'You can now serve this queue.';

  @override
  String get requestRejected => 'Request declined';

  @override
  String get rejectedBody => 'The queue owner declined your request.';

  @override
  String get removedTitle => 'You were removed';

  @override
  String get removedBody => 'The queue owner removed your operator access.';

  @override
  String get requestNotFound => 'Request not found';

  @override
  String get requestNotFoundBody => 'The request was canceled or removed.';

  @override
  String get openQueue => 'Open queue';

  @override
  String get cancelRequest => 'Cancel request';

  @override
  String get inviteGenerateFailed => 'Couldn\'t generate a code.';

  @override
  String get inviteInvalid => 'Invalid code.';

  @override
  String get inviteInvalidOrRevoked => 'Invalid or revoked code.';

  @override
  String get inviteExpired => 'Code expired. Ask the owner for a new one.';

  @override
  String get inviteOwnQueue => 'You already own this queue.';

  @override
  String get operatorsTitle => 'Operators';

  @override
  String get pendingRequestsSection => 'PENDING REQUESTS';

  @override
  String get activeOperatorsSection => 'ACTIVE OPERATORS';

  @override
  String get noPendingRequests => 'No pending requests';

  @override
  String get noOperatorsYet => 'No operators yet';

  @override
  String get inviteExplain =>
      'Anyone who gets the code requests access in the app. You approve each request.';

  @override
  String get noExpiration => 'No expiration';

  @override
  String validUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String get revokeCode => 'Revoke code';

  @override
  String get previousCodeExpired => 'The previous code has expired.';

  @override
  String get validity => 'Validity';

  @override
  String get validityHour => '1 hour';

  @override
  String get validityDay => '24 hours';

  @override
  String get validityWeek => '7 days';

  @override
  String get generateNewCode => 'Generate new code';

  @override
  String get generateCode => 'Generate code';

  @override
  String get reject => 'Decline';

  @override
  String get approve => 'Approve';

  @override
  String get removeOperatorTooltip => 'Remove operator';

  @override
  String get removeOperatorTitle => 'Remove operator?';

  @override
  String removeOperatorBody(String name) {
    return '$name will lose access to the queue. People already called by them stay in the queue.';
  }

  @override
  String get codeCopied => 'Code copied!';

  @override
  String shareCodeText(String queue, String code) {
    return 'Code to serve the queue \"$queue\" on Qio: $code\nOpen the Qio app > Join as operator.';
  }

  @override
  String get tourPanelQrTitle => 'Share the QR code';

  @override
  String get tourPanelQrBody =>
      'Your customers scan it to join the queue, with nothing to install.';

  @override
  String get tourPanelCallTitle => 'Call the next one';

  @override
  String get tourPanelCallBody =>
      'Tap here to call the next person in the queue.';

  @override
  String newPersonInQueue(String name) {
    return 'New person in the queue: $name';
  }

  @override
  String newPeopleInQueue(int count) {
    return '$count new people in the queue';
  }

  @override
  String get syncError => 'Couldn\'t sync the queue. Try reopening it.';

  @override
  String get accessEndedTitle => 'Access ended';

  @override
  String get accessEndedBody =>
      'You\'re no longer an operator of this queue. The owner removed your access or the queue was deleted.';

  @override
  String get historyTitle => 'History';

  @override
  String get reopen => 'Reopen';

  @override
  String get pause => 'Pause';

  @override
  String get close => 'Close';

  @override
  String get queueClosedTitle => 'Queue closed';

  @override
  String get noServiceInProgress => 'No service in progress';

  @override
  String get closedOwnerHint =>
      'The queue is closed. You can reopen or delete it.';

  @override
  String get closedOperatorHint =>
      'The queue is closed. Wait for the owner to reopen it.';

  @override
  String get servingByOthers => 'BEING SERVED BY OTHERS';

  @override
  String get finishService => 'Finish service';

  @override
  String get served => 'Served';

  @override
  String get noShow => 'No-show';

  @override
  String get upNext => 'UP NEXT';

  @override
  String get nobodyInQueue => 'Nobody in the queue';

  @override
  String get deleteQueue => 'Delete queue';

  @override
  String get callNext => 'Call next';

  @override
  String get operatorsAndInvites => 'Operators and invites';

  @override
  String get qrSemantics => 'QR code to join the queue';

  @override
  String get scanToJoin => 'Scan to join the queue';

  @override
  String get copyLinkSemantics => 'Copy queue link';

  @override
  String get copyLink => 'Copy link';

  @override
  String get printablePoster => 'Printable poster';

  @override
  String get linkCopied => 'Link copied!';

  @override
  String get deleteQueueTitle => 'Delete queue?';

  @override
  String get deleteQueueBody =>
      'This action is permanent. The queue and its entire service history will be erased.';

  @override
  String get nobodyCalled => 'Nobody called';

  @override
  String get callNextHint => 'Tap \"Call next\" to get started';

  @override
  String get callingNow => 'NOW CALLING';

  @override
  String waitTileSubtitle(int ticket, int minutes) {
    return '#$ticket · $minutes min';
  }

  @override
  String ticketAndName(int ticket, String name) {
    return '#$ticket $name';
  }

  @override
  String get exportTooltip => 'Export';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get nothingToExport => 'Nothing to export with this filter.';

  @override
  String get exportError => 'Couldn\'t export the history.';

  @override
  String get loadHistoryError =>
      'Couldn\'t load the history. Please try again.';

  @override
  String get noHistoryYet => 'No services yet';

  @override
  String get noHistoryInFilter => 'No services match this filter';

  @override
  String get filterAll => 'All';

  @override
  String get periodToday => 'Today';

  @override
  String get period7Days => '7 days';

  @override
  String get periodAll => 'All time';

  @override
  String get servedPlural => 'Served';

  @override
  String get noShowPlural => 'No-shows';

  @override
  String get leftPlural => 'Left the queue';

  @override
  String get avgWait => 'Average wait';

  @override
  String get avgService => 'Average service';

  @override
  String get resultLeft => 'Left';

  @override
  String waitSubtitle(String duration) {
    return 'wait $duration';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get durationLessThanMinute => '<1 min';

  @override
  String get csvTicket => 'ticket';

  @override
  String get csvName => 'name';

  @override
  String get csvPhone => 'phone';

  @override
  String get csvResult => 'result';

  @override
  String get csvEntered => 'joined';

  @override
  String get csvCalled => 'called';

  @override
  String get csvFinished => 'finished';

  @override
  String get pdfTitle => 'Qio - Service history';

  @override
  String pdfGeneratedAt(String date) {
    return 'Generated on $date';
  }

  @override
  String get pdfTotal => 'Total';

  @override
  String get pdfNoRecords => 'No services in this period.';

  @override
  String get colTicket => 'Ticket';

  @override
  String get colName => 'Name';

  @override
  String get colPhone => 'Phone';

  @override
  String get colResult => 'Result';

  @override
  String get colEntered => 'Joined';

  @override
  String get colCalled => 'Called';

  @override
  String get colFinished => 'Finished';

  @override
  String get posterTitle => 'QR poster';

  @override
  String get qrColor => 'QR COLOR';

  @override
  String get qrColorBlue => 'Blue';

  @override
  String get qrColorBlack => 'Black';

  @override
  String get qrColorDarkGreen => 'Dark green';

  @override
  String get shareImage => 'Share image';

  @override
  String get shareImageError => 'Couldn\'t share the image.';

  @override
  String get printPosterError => 'Couldn\'t print the poster.';

  @override
  String get skip => 'SKIP';

  @override
  String stepOf(int index, int total) {
    return '$index of $total';
  }

  @override
  String get tapToContinue => 'Tap to continue';

  @override
  String avatarLabel(String name) {
    return 'Avatar: $name';
  }
}
