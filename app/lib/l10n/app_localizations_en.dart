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
  String get deleteAccountTitle => 'Delete my account';

  @override
  String get deleteAccountZone => 'Danger zone';

  @override
  String get deleteAccountSubtitle =>
      'Erases your account, queues, history, ratings and devices. This can\'t be undone.';

  @override
  String get deleteAccountWarning =>
      'All your queues, service history, ratings, groups and your account will be permanently erased. People waiting in your queues lose their ticket. If you are an operator on other people\'s queues, only your link is removed.';

  @override
  String get deleteAccountConfirmLabel =>
      'Type DELETE or your email to confirm';

  @override
  String get deleteAccountPasswordLabel => 'Current password';

  @override
  String get deleteAccountGoogleHint =>
      'You will confirm your identity with Google before deleting.';

  @override
  String get deleteAccountConfirmButton => 'Delete permanently';

  @override
  String get deleteAccountProgress =>
      'Deleting your data. This may take a moment.';

  @override
  String get deleteAccountReauthFailed =>
      'Couldn\'t confirm your identity. Check your password and try again.';

  @override
  String get deleteAccountError =>
      'Deletion didn\'t finish. Some data may already be gone. Try again to complete it.';

  @override
  String get deleteAccountRetry => 'Try again';

  @override
  String get deleteAccountRecentLogin =>
      'For your security, confirm your identity again to finish the deletion.';

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
      'Tap the card to open the panel and call people. Pause or show the QR code from the card shortcuts.';

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
  String get avgRating => 'Average rating';

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

  @override
  String get metricsTitle => 'Metrics';

  @override
  String get metricsTooltip => 'Queue metrics';

  @override
  String get metricsTotal => 'Services';

  @override
  String get peakHoursTitle => 'Demand peaks';

  @override
  String get peakHoursSubtitle => 'People who joined by hour';

  @override
  String peakHoursTop(String hours) {
    return 'Busiest hours: $hours';
  }

  @override
  String get noPeakData => 'No data in this period';

  @override
  String get mostActiveQueues => 'Most active queues';

  @override
  String queueActivityLine(int total, int rate) {
    return '$total services · $rate% no-show';
  }

  @override
  String get noMetricsData => 'No services in this period';

  @override
  String get loadMetricsError => 'Could not load metrics. Please try again.';

  @override
  String get noQueuesYet => 'You don\'t have any queues yet';

  @override
  String get retry => 'Try again';

  @override
  String get forgotPassword => 'Forgot password';

  @override
  String get resetEmailRequired => 'Enter your email to reset the password';

  @override
  String get resetEmailSent =>
      'If an account exists for that email, we sent a link to reset the password.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get offlineBanner => 'No connection. Data may be out of date.';

  @override
  String get loadErrorTitle => 'Something went wrong';

  @override
  String get loadErrorBody =>
      'We could not load your data. Check your connection and try again.';

  @override
  String get hapticsTitle => 'Vibration';

  @override
  String get hapticsSubtitle =>
      'Vibrate when calling, finishing and confirming actions';

  @override
  String get analyticsTitle => 'Help improve Qio';

  @override
  String get analyticsSubtitle =>
      'Sends anonymous usage statistics (no names, phone numbers or customer data). You can turn this off at any time.';

  @override
  String get nobodyInQueueHint =>
      'When someone joins through the QR code, they show up here.';

  @override
  String get emptyHistoryHint => 'Finished services show up here.';

  @override
  String get emptyMetricsHint =>
      'Pick another period or wait for the first services.';

  @override
  String get discardTitle => 'Discard changes?';

  @override
  String get discardBody =>
      'You already filled in some fields. If you leave now, you will lose what you typed.';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get discard => 'Discard';

  @override
  String get maxWaitingLabel => 'Maximum people waiting (optional)';

  @override
  String get maxWaitingHint => 'No limit';

  @override
  String get maxWaitingInvalid => 'Use a number from 1 to 1000';

  @override
  String get queueLimitTitle => 'Queue limit';

  @override
  String get queueLimitNone => 'No waiting limit';

  @override
  String queueLimitValue(int max) {
    return 'Up to $max people waiting';
  }

  @override
  String get save => 'Save';

  @override
  String get pauseQueueTitle => 'Pause the queue';

  @override
  String get closeQueueTitle => 'Close the queue';

  @override
  String get statusMessageLabel => 'Message for customers (optional)';

  @override
  String get statusSuggestionBack10 => 'Back in 10 minutes';

  @override
  String get statusSuggestionBreak => 'Quick break';

  @override
  String get statusSuggestionClosedToday => 'Queue closed for today';

  @override
  String get resumeAtLabel => 'Expected return';

  @override
  String get resumeAtNone => 'No estimate';

  @override
  String get clear => 'Clear';

  @override
  String waitingCounter(int count, int max) {
    return '$count/$max waiting';
  }

  @override
  String get callAgain => 'Call again';

  @override
  String get callNow => 'Call now';

  @override
  String get moveToEnd => 'Move to the end';

  @override
  String get moreActions => 'More actions';

  @override
  String calledTimes(int count) {
    return 'Called ${count}x';
  }

  @override
  String get callResent => 'Call sent again';

  @override
  String movedToEnd(String name) {
    return '$name moved to the end of the queue';
  }

  @override
  String get entryUnavailable => 'This person is no longer waiting';

  @override
  String get scheduleTitle => 'Business hours';

  @override
  String get scheduleOff => 'Off';

  @override
  String scheduleHours(String days, String open, String close) {
    return '$days · $open–$close';
  }

  @override
  String get scheduleEnabled => 'Open and close automatically';

  @override
  String get scheduleDays => 'Days';

  @override
  String get scheduleOpens => 'Opens';

  @override
  String get scheduleCloses => 'Closes';

  @override
  String get scheduleInvalidDays => 'Choose at least one day';

  @override
  String get scheduleInvalidTime => 'Opening and closing times must differ';

  @override
  String get scheduleNote =>
      'Brasília time. If you open, pause or close manually, it holds until the next scheduled opening or closing.';

  @override
  String get linkForCustomers =>
      'This link is for customers. Opening in the browser.';

  @override
  String get brandTitle => 'Queue branding';

  @override
  String get brandSubtitle => 'Color and logo on the customer page';

  @override
  String get brandColorLabel => 'Color';

  @override
  String get brandLogoLabel => 'Logo';

  @override
  String get brandChooseImage => 'Choose image';

  @override
  String get brandError =>
      'Could not save. Check your connection and try again.';

  @override
  String get pushTitle => 'New entry alerts';

  @override
  String get pushSubtitle =>
      'Notify when someone joins the queue, even with the app closed';

  @override
  String get pushPromptTitle => 'Get alerts?';

  @override
  String get pushPromptBody =>
      'We notify you when someone joins one of your queues, even with the app closed. You can change this later in My account.';

  @override
  String get pushPromptNotNow => 'Not now';

  @override
  String get pushPromptEnable => 'Turn on';

  @override
  String get pushDenied =>
      'Permission denied. Turn on notifications in the system settings.';

  @override
  String get byOperatorTitle => 'By attendant';

  @override
  String get operatorFilterAll => 'All queues';

  @override
  String get ownerAttendant => 'Owner';

  @override
  String get formerOperator => 'former operator';

  @override
  String get noOperatorData =>
      'No attended entries by attendant in this period';

  @override
  String historyTruncatedWarning(int limit) {
    return 'Showing only the $limit most recent records of a queue; numbers may be incomplete.';
  }

  @override
  String operatorCountsLine(int served, int noShow) {
    return '$served served · $noShow no-shows';
  }

  @override
  String operatorDetailLine(String avg, String rating) {
    return 'Avg. service: $avg · Rating: $rating';
  }

  @override
  String get operatorFilterLabel => 'Filter by queue';

  @override
  String get metricsPdfTitle => 'Qio - Queue metrics';

  @override
  String get csvPeriod => 'period';

  @override
  String get csvScope => 'attendant scope';

  @override
  String get csvGeneratedAt => 'generated at';

  @override
  String get csvMetric => 'metric';

  @override
  String get csvValue => 'value';

  @override
  String get csvHour => 'hour';

  @override
  String get csvEntries => 'entries';

  @override
  String get csvPosition => 'position';

  @override
  String get csvQueue => 'queue';

  @override
  String get csvTotal => 'total';

  @override
  String get csvServed => 'served';

  @override
  String get csvNoShow => 'no-shows';

  @override
  String get csvLeft => 'left';

  @override
  String get csvNoShowRatePct => 'no-show rate (%)';

  @override
  String get csvAvgWaitMin => 'avg. wait (min)';

  @override
  String get csvAvgServiceMin => 'avg. service (min)';

  @override
  String get csvAvgRating => 'avg. rating';

  @override
  String get csvRatingCount => 'rating count';

  @override
  String get csvAttendant => 'attendant';

  @override
  String get exportMetricsError => 'Couldn\'t export the metrics.';

  @override
  String get groups => 'Groups';

  @override
  String get groupNew => 'New group…';

  @override
  String get groupRename => 'Rename group';

  @override
  String get groupDelete => 'Delete group';

  @override
  String groupDeleteConfirm(String name) {
    return 'Delete the group \"$name\"? Its queues become ungrouped.';
  }

  @override
  String get groupNone => 'No group';

  @override
  String get groupName => 'Group name';

  @override
  String groupLimitReached(int max) {
    return 'Limit of $max groups reached.';
  }

  @override
  String queueLimitReached(int max) {
    return 'Limit of $max queues reached. Delete a queue to create another.';
  }

  @override
  String get groupLabel => 'Group';

  @override
  String get groupsEmpty =>
      'No groups yet. Create one to organize your queues.';

  @override
  String get groupPermissionDenied =>
      'No permission to change groups. Update the app and try again.';

  @override
  String get metricsScopeLabel => 'Metrics scope';

  @override
  String get metricsScopeAll => 'All queues';

  @override
  String metricsScopeGroup(String name) {
    return 'Group: $name';
  }

  @override
  String metricsScopeQueue(String name) {
    return 'Queue: $name';
  }

  @override
  String get groupCompareTitle => 'Queue comparison in the group';

  @override
  String groupCompareLine(int total, String wait, int rate, String rating) {
    return '$total served · wait $wait · $rate% no-show · rating $rating';
  }

  @override
  String get csvDataScope => 'metrics scope';

  @override
  String get groupsUnavailable =>
      'Groups unavailable. Update the app or the Firestore rules.';

  @override
  String get alertsTitle => 'Operational alerts';

  @override
  String get alertsEnable => 'Get alerts for this queue';

  @override
  String get alertsWaitLimit => 'Estimated wait above';

  @override
  String get alertsNoShowLimit => 'No-show rate today from';

  @override
  String get alertsIdleLimit =>
      'Queue stalled with people waiting for more than';

  @override
  String get alertsCooldown => 'Minimum interval between alerts';

  @override
  String get alertsPushOff =>
      'Notifications are turned off. Enable them to receive alerts.';

  @override
  String get alertsOff => 'Off';

  @override
  String alertsActive(int count) {
    return '$count active rules';
  }

  @override
  String alertsMinutes(int n) {
    return '$n min';
  }

  @override
  String alertsPercent(int n) {
    return '$n%';
  }

  @override
  String get alertsNoRule => 'Turn on at least one rule to receive alerts.';

  @override
  String get alertsNotify => 'Receive alerts on this account';

  @override
  String get waitDistributionTitle => 'Wait and calls';

  @override
  String get medianWait => 'Median';

  @override
  String get p90Wait => 'P90';

  @override
  String get waitBucketUnder5 => 'Under 5 min';

  @override
  String get waitBucket5to15 => '5–15 min';

  @override
  String get waitBucket15to30 => '15–30 min';

  @override
  String get waitBucketOver30 => 'Over 30 min';

  @override
  String get recallsTitle => 'Recalls';

  @override
  String get skipsTitle => 'Moved to end';

  @override
  String recallsStat(int entries, int total, int pct, int recalls) {
    return '$entries entries of $total ($pct%) · $recalls recalls';
  }

  @override
  String skipsStat(int entries, int total, int skips) {
    return '$entries entries of $total · $skips moved to end';
  }

  @override
  String get csvWaitSamples => 'wait samples';

  @override
  String get csvMedianWaitMin => 'median (min)';

  @override
  String get csvP90WaitMin => 'P90 (min)';

  @override
  String get csvWaitRange => 'wait range';

  @override
  String get csvCalledEntries => 'called entries';

  @override
  String get csvRecallsTotal => 'recalls';

  @override
  String get csvRecalledEntries => 'entries with recall';

  @override
  String get csvRecallRatePct => 'entries with recall over called (%)';

  @override
  String get csvSkipsTotal => 'moved to end';

  @override
  String get csvSkippedEntries => 'entries moved to end';

  @override
  String get p90Insufficient => 'not enough samples';

  @override
  String get weekdayDemandTitle => 'Busiest days';

  @override
  String get heatmapTitle => 'Heatmap: day × hour';

  @override
  String demandPeakSummary(String day, String from, String to) {
    return 'Peak: $day, $from–$to';
  }

  @override
  String heatmapCellSemantics(String day, String hour, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arrivals',
      one: '1 arrival',
    );
    return '$day, $hour: $_temp0';
  }

  @override
  String get csvWeekday => 'day';

  @override
  String get csvArrivals => 'arrivals';

  @override
  String get heatmapLegendLess => 'less';

  @override
  String get heatmapLegendMore => 'more';

  @override
  String weekdayChartSemantics(String details) {
    return 'Arrivals per day: $details';
  }

  @override
  String get period30Days => '30 days';

  @override
  String get periodCustom => 'Custom';

  @override
  String deltaUp(String pct) {
    return '▲ $pct%';
  }

  @override
  String deltaDown(String pct) {
    return '▼ $pct%';
  }

  @override
  String get deltaSame => '= stable';

  @override
  String deltaPoints(String pp) {
    return '$pp pp';
  }

  @override
  String get deltaRose => 'rose';

  @override
  String get deltaFell => 'fell';

  @override
  String get deltaVsPrevious => 'vs. previous period';

  @override
  String get trendTitle => 'Daily trend';

  @override
  String get trendSeriesTotal => 'Entries per day';

  @override
  String get trendSeriesWait => 'Average wait';

  @override
  String get trendSeriesNoShow => 'No-show';

  @override
  String trendSummary(String avg, String peakDay) {
    return 'Average of $avg per day, peak on $peakDay';
  }

  @override
  String get csvDate => 'date';

  @override
  String get csvCompareTitle => 'Comparison with the previous period';

  @override
  String get csvCurrent => 'current';

  @override
  String get csvPrevious => 'previous';

  @override
  String get csvDeltaPct => 'change (%)';

  @override
  String get csvDeltaPoints => 'change (pp)';

  @override
  String get pdfVsPrevious => 'vs. previous';

  @override
  String customRangeLimited(int days) {
    return 'Range limited to $days days';
  }

  @override
  String deltaPointsUp(String pp) {
    return '▲ $pp pp';
  }

  @override
  String deltaPointsDown(String pp) {
    return '▼ $pp pp';
  }

  @override
  String get trendToggleWait => 'Wait';

  @override
  String get trendToggleNoShow => 'No-show';

  @override
  String trendMax(String value) {
    return 'max $value';
  }

  @override
  String trendDaySummary(String day, int count, String series, String value) {
    return '$day: $count entries, $series $value';
  }

  @override
  String get queueModeLabel => 'Queue mode';

  @override
  String get modeQueue => 'First come, first served';

  @override
  String get modeSchedule => 'Scheduled time';

  @override
  String get slotsEditorTitle => 'Time slots';

  @override
  String get slotsEditorHint => 'Time zone America/Sao_Paulo; repeat every day';

  @override
  String get slotTime => 'Time';

  @override
  String slotCapacity(int count) {
    return 'Spots: $count';
  }

  @override
  String get addSlot => 'Add time slot';

  @override
  String get removeSlot => 'Remove time slot';

  @override
  String get slotsRequired => 'Add at least one time slot';

  @override
  String get slotsDuplicate => 'Some time slots are repeated';

  @override
  String slotsTooMany(int max) {
    return 'At most $max time slots';
  }

  @override
  String get slotsInvalid => 'Invalid time or spots';

  @override
  String slotsOutsideSchedule(String time) {
    return 'Outside opening hours: $time';
  }

  @override
  String slotsTileSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count time slots',
      one: '1 time slot',
    );
    return '$_temp0';
  }

  @override
  String waitTileSlot(String time) {
    return 'Slot $time';
  }

  @override
  String get slotTimeChangeWarning =>
      'People already in this slot keep their spot; taken spots still count.';

  @override
  String get editQueue => 'Edit queue';

  @override
  String get editQueueHint => 'Name, description and average time';

  @override
  String get queueUpdated => 'Queue updated';

  @override
  String get duplicateQueue => 'Duplicate queue';

  @override
  String get duplicateQueueHint =>
      'Copies limit, hours, color, mode, group and alerts';

  @override
  String get duplicateQueueCopyWord => 'copy';

  @override
  String get queueDuplicated => 'Queue duplicated';

  @override
  String get advancedOptions => 'Advanced options';

  @override
  String get queueNameTooLong => 'At most 60 characters';

  @override
  String get descriptionTooLong => 'At most 300 characters';

  @override
  String get avgServiceInvalid => 'Enter 1 to 240 minutes';

  @override
  String get avgServiceAutoHint =>
      'The manual time only applies until the automatic estimate exists, calculated from served customers.';

  @override
  String get savingQueue => 'Saving…';

  @override
  String get actionErrorOffline =>
      'No connection. Check your internet and try again.';

  @override
  String get actionErrorAccessEnded =>
      'Access ended or no permission for this action.';

  @override
  String get actionErrorConflict => 'The queue changed. Please try again.';

  @override
  String get undo => 'Undo';

  @override
  String finishedServedUndo(String name) {
    return '$name marked as served';
  }

  @override
  String finishedNoShowUndo(String name) {
    return '$name marked as no-show';
  }

  @override
  String get queueSettingsTitle => 'Queue settings';

  @override
  String get queueQrShortcut => 'Queue QR code';

  @override
  String get queueQrTitle => 'QR code';

  @override
  String get queueGoneNotice => 'This queue no longer exists';

  @override
  String get tourPanelSettingsTitle => 'QR code and settings';

  @override
  String get tourPanelSettingsBody =>
      'Tap the gear to see the QR code and adjust the queue.';

  @override
  String get tourHomeAccountTitle => 'Your account and invites';

  @override
  String get tourHomeAccountBody =>
      'Find your account here, plus the option to join as an operator with an invite code.';

  @override
  String get quickQr => 'QR code';

  @override
  String quickPauseLabel(String name) {
    return 'Pause queue $name';
  }

  @override
  String quickReopenLabel(String name) {
    return 'Reopen queue $name';
  }

  @override
  String quickQrLabel(String name) {
    return 'Show QR code for queue $name';
  }

  @override
  String get searchQueuesHint => 'Search queue by name';

  @override
  String get sortQueues => 'Sort queues';

  @override
  String get sortByName => 'Name';

  @override
  String get sortByRecent => 'Most recent';

  @override
  String get sortByWaiting => 'Longest wait';

  @override
  String get noQueuesMatch => 'No queues found';

  @override
  String get addPerson => 'Add person';

  @override
  String get addPersonTitle => 'Add person to the queue';

  @override
  String get addPersonHint =>
      'For people at the counter who do not use the QR code.';

  @override
  String get manualPhoneLabel => 'Phone (optional)';

  @override
  String get manualPhoneInvalid => 'Use the format (00) 00000-0000';

  @override
  String get manualNameRequired => 'Enter a name up to 60 characters';

  @override
  String get manualSlotLabel => 'Time slot';

  @override
  String manualSlotOption(String time, int capacity) {
    return '$time ($capacity spots)';
  }

  @override
  String get manualSlotRequiredField => 'Choose a time slot';

  @override
  String get manualAddConfirm => 'Add';

  @override
  String manualAdded(String name, int ticket) {
    return '$name joined the queue with ticket $ticket';
  }

  @override
  String get manualBadge => 'Counter';

  @override
  String get manualAddQueueFull => 'The queue is full right now.';

  @override
  String get manualAddSlotFull => 'This time slot is full.';

  @override
  String get manualAddSlotRequired => 'Choose a valid time slot.';

  @override
  String get manualAddSlotPassed => 'This time slot has already passed.';

  @override
  String get manualAddNotOpen => 'The queue must be open to add people.';

  @override
  String get manualAddInvalid => 'Check the name and phone you entered.';

  @override
  String get manualAddRateLimited =>
      'Too many additions in a short time. Wait a few minutes.';

  @override
  String get manualAddPhoneDuplicate => 'This phone is already in the queue.';

  @override
  String callPhoneTooltip(String name) {
    return 'Call $name';
  }

  @override
  String get callPhoneFailed => 'Could not open the dialer';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get termsOfUse => 'Terms of use';

  @override
  String get posterSize => 'POSTER SIZE';

  @override
  String get posterSizeA4 => 'A4';

  @override
  String get posterSizeA5 => 'A5';

  @override
  String get posterSizeTable => 'Table card (10×15 cm)';

  @override
  String get posterHeadlineLabel => 'Poster headline (optional)';

  @override
  String get posterHeadlineHint =>
      'E.g. Get your spot without standing in line';

  @override
  String get posterHeadlineInvalid => 'Use up to 60 characters.';

  @override
  String get sharePdf => 'Share PDF';

  @override
  String get sharePdfError => 'Could not share the PDF.';

  @override
  String posterPreviewSemantics(String size) {
    return 'Poster preview, $size';
  }

  @override
  String get slugTitle => 'Short link';

  @override
  String get slugNone => 'Not set';

  @override
  String get slugRemove => 'Remove short link';

  @override
  String get slugDialogLabel => 'Link name';

  @override
  String get slugDialogHint => 'my-shop';

  @override
  String slugPreview(String url) {
    return 'Link: $url';
  }

  @override
  String get slugInvalid =>
      'Use 3 to 40 lowercase letters, numbers or hyphens, with no hyphen at the start or end.';

  @override
  String get slugReservedError => 'That name is reserved. Choose another.';

  @override
  String get slugTakenError => 'That link is already in use. Choose another.';

  @override
  String get slugSaved => 'Short link saved';

  @override
  String get slugRemoved => 'Short link removed';

  @override
  String get slugReleaseNotice =>
      'Changing the link invalidates QR codes printed with the old link. The old link stays reserved for you for 30 days.';

  @override
  String get posterNameLossy =>
      'Some characters are not available in the PDF font and will be omitted or replaced.';

  @override
  String get posterNameFallback => 'Queue';

  @override
  String get exportCsvWithPhone => 'Export CSV with phone';

  @override
  String get exportPdfWithPhone => 'Export PDF with phone';

  @override
  String get exportPhoneTitle => 'Include phone number?';

  @override
  String get exportPhoneWarning =>
      'The phone number is personal data (LGPD). Exports leave it out by default. Include it only if you need it and protect the file.';

  @override
  String get exportPhoneConfirm => 'Include phone';

  @override
  String get anonymizePhoneTitle => 'Do not keep phone in history';

  @override
  String get anonymizePhoneHint =>
      'When a service is completed, the phone number is not saved to the history.';

  @override
  String get expiryTitle => 'Expire forgotten entries';

  @override
  String get expiryHint =>
      'Removes people who kept waiting with no activity. Does not affect people already called.';

  @override
  String expiryAfterHours(int hours) {
    return 'Expire after $hours h';
  }

  @override
  String get expiryClearOnClose => 'Clear the queue when closing on schedule';

  @override
  String get expiryResetTicketDaily => 'Reset the ticket number every day';

  @override
  String get expiryResetTicketDailyHint =>
      'Resets the first time the queue is empty each new day.';

  @override
  String get dataSubjectTitle => 'Customer data';

  @override
  String get dataSubjectSubtitle =>
      'Handle access, correction or erasure requests for a customer\'s data (LGPD).';

  @override
  String get dataSubjectPhoneLabel => 'Customer phone';

  @override
  String get dataSubjectSearch => 'Search';

  @override
  String get dataSubjectNone => 'No data found for this phone in your queues.';

  @override
  String dataSubjectFound(int count) {
    return 'Found in $count queue(s)';
  }

  @override
  String dataSubjectQueueCounts(int history, int feedback, int entries) {
    return '$history in history, $feedback ratings, $entries in line now';
  }

  @override
  String dataSubjectPeriod(String from, String to) {
    return 'From $from to $to';
  }

  @override
  String get dataSubjectExport => 'Export data (CSV)';

  @override
  String get dataSubjectExportTruncated =>
      'The export was limited to the first 5000 records.';

  @override
  String get dataSubjectAnonymize => 'Anonymize';

  @override
  String get dataSubjectDelete => 'Delete';

  @override
  String get dataSubjectConfirmTitleAnonymize =>
      'Anonymize this customer\'s data?';

  @override
  String get dataSubjectConfirmTitleDelete => 'Delete this customer\'s data?';

  @override
  String get dataSubjectConfirmBodyAnonymize =>
      'The name becomes \"Anonymous\", the phone is removed from the history and rating comments are erased. If the customer is in a line right now, they are removed. This cannot be undone.';

  @override
  String get dataSubjectConfirmBodyDelete =>
      'Deletes the history and ratings for this phone and removes the customer from any active line. This cannot be undone.';

  @override
  String get dataSubjectConfirmLabel => 'Type the phone again to confirm';

  @override
  String get dataSubjectConfirmButton => 'Confirm';

  @override
  String dataSubjectDone(int count) {
    return 'Done: $count record(s) handled.';
  }

  @override
  String get dataSubjectPartial =>
      'Some records were not handled. Search again and retry.';

  @override
  String get dataSubjectRateLimited =>
      'Too many requests in a row. Wait a moment and try again.';

  @override
  String get dataSubjectAuditNote =>
      'Each request is logged for auditing, without name or phone.';

  @override
  String get dataSubjectReauthTitle => 'Confirm your identity';

  @override
  String get dataSubjectReauthHint =>
      'You will confirm your identity with Google.';

  @override
  String get dataSubjectReauthButton => 'Confirm identity';

  @override
  String cqStepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get cqContinue => 'Continue';

  @override
  String get cqSkip => 'Skip';

  @override
  String get cqQuickCreate => 'Create now';

  @override
  String get cqMoreDetails => 'More details';

  @override
  String get cqNameTitle => 'What is the queue called?';

  @override
  String get cqNameHint =>
      'The name is enough. You can adjust the rest later in the panel.';

  @override
  String get cqModeTitle => 'How do people join?';

  @override
  String get cqModeQueueHint => 'Whoever arrives joins the end of the line.';

  @override
  String get cqModeScheduleHint =>
      'Each person picks one of the times you set.';

  @override
  String get cqSuggestionsTitle => 'Time suggestions';

  @override
  String get cqSuggestEvery30 => 'Add times every 30 min, 9am to 5pm';

  @override
  String get cqSuggestEveryHour => 'Add times every hour, 9am to 5pm';

  @override
  String get cqCapacityTitle => 'Average time and waiting limit';

  @override
  String cqCapacityHint(int minutes) {
    return 'We use the average time to estimate the wait. If you skip, $minutes min per customer and no limit apply.';
  }

  @override
  String get cqAppearanceTitle => 'Pick a color';

  @override
  String get cqAppearanceHint =>
      'It shows on the page your customers see. Optional.';

  @override
  String get cqScheduleTitle => 'When is the queue open?';

  @override
  String get cqScheduleHint =>
      'By default the queue is always open. You can pause or close it whenever you want.';

  @override
  String get cqReviewTitle => 'Review and create';

  @override
  String get cqReviewHint => 'Tap Edit to change any item.';

  @override
  String get cqEdit => 'Edit';

  @override
  String get cqSummaryEntry => 'Joining';

  @override
  String get cqSummaryCapacity => 'Time and limit';

  @override
  String get cqSummarySchedule => 'Operation';

  @override
  String cqAverageTime(String time) {
    return 'Average time: $time';
  }

  @override
  String cqWaitingLimit(String limit) {
    return 'Waiting limit: $limit';
  }

  @override
  String cqLimitPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0';
  }

  @override
  String get cqAlwaysOpen => 'Always open';

  @override
  String get cqNoExpiry => 'Never expire';

  @override
  String get cqDefaultColor => 'Default';

  @override
  String get cqGroupChosen => 'In a group';

  @override
  String get cqSummaryName => 'Name';

  @override
  String get cqCreateTimeout =>
      'No response. The queue may have been created: check your list before trying again.';

  @override
  String get cqResumeTitle => 'Pick up where you left off?';

  @override
  String get cqResumeBody =>
      'You have a queue in progress that was not created. Continue where you left off or discard it?';

  @override
  String get cqResume => 'Continue';

  @override
  String get cqDiscardDraft => 'Discard';

  @override
  String get cqSaveDraft => 'Save draft';

  @override
  String get cqDraftDiscardBody =>
      'You have filled in some fields. Save a draft to continue later or discard what you typed.';

  @override
  String get cqCreatedTitle => 'Queue created';

  @override
  String get cqCreatedHint =>
      'Share the link or show the QR code so people can join.';

  @override
  String get cqOpenPanel => 'Open panel';

  @override
  String get cqPolishTitle => 'Make your queue nicer and more complete';

  @override
  String get cqShortcutLogo => 'Logo and color';

  @override
  String get cqShortcutShortLink => 'Short link';

  @override
  String get cqShortcutOperators => 'Operators';

  @override
  String get cqShortcutAlerts => 'Alerts';

  @override
  String get cqLimitTitle => 'Queue limit reached';

  @override
  String get cqCheckingLimit => 'Checking your queue limit';

  @override
  String get cqShareLink => 'Share link';

  @override
  String get cqAlertsTitle => 'Want alerts for this queue?';

  @override
  String get cqAlertsHint =>
      'Optional. We notify you when the wait, no-shows or a stalled queue go past the limit you pick.';

  @override
  String get cqAlertsPushNote =>
      'Alerts arrive as notifications. Whether this account receives them is an option on the Operational alerts screen, in the queue settings.';

  @override
  String get cqSummaryAlerts => 'Alerts';

  @override
  String get metricsScopeUngrouped => 'Queues without a group';

  @override
  String get groupOverviewTitle => 'By group';

  @override
  String get groupOverviewHint => 'Tap a group to see only its queues.';

  @override
  String get groupOverviewOpenHint => 'Show only this group';

  @override
  String metricsGroupQueues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count queues',
      one: '1 queue',
    );
    return '$_temp0';
  }

  @override
  String get groupPartialData => 'partial data';

  @override
  String get cmpColQueue => 'Queue';

  @override
  String get cmpColGroup => 'Group';

  @override
  String get cmpColServed => 'Served';

  @override
  String get cmpColWait => 'Wait';

  @override
  String get cmpColNoShow => 'No-show';

  @override
  String get cmpColRating => 'Rating';

  @override
  String sortByHint(String column) {
    return 'Sort by $column';
  }

  @override
  String get sortAscending => 'ascending order';

  @override
  String get sortDescending => 'descending order';

  @override
  String get scopePickerTitle => 'Choose scope';

  @override
  String get scopeSearchHint => 'Search group or queue';

  @override
  String get scopeNoResults => 'No results';

  @override
  String get csvGroup => 'group';

  @override
  String get csvQueuesCount => 'queues';

  @override
  String get csvPartialData => 'partial data';

  @override
  String get csvYes => 'yes';

  @override
  String get csvNo => 'no';

  @override
  String get csvDeltaTotalPct => 'served change (%)';

  @override
  String get csvDeltaWaitPct => 'average wait change (%)';

  @override
  String get csvDeltaMedianPct => 'median change (%)';

  @override
  String get csvDeltaP90Pct => 'P90 change (%)';

  @override
  String get csvDeltaNoShowPoints => 'no-show change (p.p.)';

  @override
  String groupSectionQueues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count queues',
      one: '$count queue',
    );
    return '$_temp0';
  }

  @override
  String groupSectionWaiting(int count) {
    return '$count waiting';
  }

  @override
  String get groupSectionExpanded => 'expanded';

  @override
  String get groupSectionCollapsed => 'collapsed';

  @override
  String groupSectionSemantics(
    String name,
    String queues,
    String waiting,
    String state,
  ) {
    return '$name, $queues, $waiting, $state';
  }

  @override
  String groupChipSemantics(String name) {
    return 'Group: $name';
  }

  @override
  String groupQueueCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count queues',
      one: '1 queue',
      zero: 'No queues',
    );
    return '$_temp0';
  }

  @override
  String groupDeleteConfirmCount(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count queues will become ungrouped.',
      one: '1 queue will become ungrouped.',
    );
    return 'Delete the group \"$name\"? $_temp0';
  }

  @override
  String groupBatchMenuLabel(String name) {
    return 'Batch actions for group $name';
  }

  @override
  String get groupPauseAll => 'Pause all';

  @override
  String get groupCloseAll => 'Close all';

  @override
  String get groupReopenAll => 'Reopen all';

  @override
  String groupBatchConfirmPause(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count queues',
      one: '1 queue',
    );
    return 'Pause $_temp0 in group \"$name\"?';
  }

  @override
  String groupBatchConfirmClose(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count queues',
      one: '1 queue',
    );
    return 'Close $_temp0 in group \"$name\"?';
  }

  @override
  String groupBatchConfirmReopen(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count queues',
      one: '1 queue',
    );
    return 'Reopen $_temp0 in group \"$name\"?';
  }

  @override
  String groupBatchDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count queues updated',
      one: '1 queue updated',
    );
    return '$_temp0';
  }

  @override
  String groupBatchPartial(int done, int total) {
    return '$done of $total updated. Try again for the rest.';
  }

  @override
  String get groupBatchEmpty => 'No queues in the group to update.';

  @override
  String groupReorderHandle(String name) {
    return 'Drag to reorder group \"$name\"';
  }

  @override
  String get groupMoveUp => 'Move up';

  @override
  String get groupMoveDown => 'Move down';

  @override
  String groupMoved(String name, int position) {
    return 'Group \"$name\" at position $position';
  }

  @override
  String get groupColor => 'Group color';

  @override
  String groupColorOf(String name) {
    return 'Color of group \"$name\"';
  }

  @override
  String get groupColorNone => 'No color';

  @override
  String get queueSelect => 'Select queues';

  @override
  String get selectionExit => 'Exit selection';

  @override
  String selectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count queues selected',
      one: '1 queue selected',
      zero: 'No queues selected',
    );
    return '$_temp0';
  }

  @override
  String queueSelectLabel(String name) {
    return 'Select queue $name';
  }

  @override
  String get moveToGroup => 'Move to group…';

  @override
  String moveToGroupTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Move $count queues to',
      one: 'Move 1 queue to',
    );
    return '$_temp0';
  }

  @override
  String moveGroupDone(int count, String group) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count queues moved',
      one: '1 queue moved',
    );
    return '$_temp0 to \"$group\"';
  }

  @override
  String moveGroupPartial(int done, int total) {
    return '$done of $total queues moved. Try again for the rest.';
  }

  @override
  String get moveGroupEmpty => 'None of the selected queues could be moved.';

  @override
  String get groupApplyAlerts => 'Apply alerts to all queues';

  @override
  String groupAlertsDialogTitle(String name) {
    return 'Alerts for group \"$name\"';
  }

  @override
  String get groupAlertsDialogHint =>
      'This setup will be copied to every queue in the group, replacing the current one.';

  @override
  String get groupAlertsContinue => 'Continue';

  @override
  String groupAlertsConfirm(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count queues',
      one: '1 queue',
    );
    return 'Apply this alerts setup to $_temp0 in group \"$name\"? The current alerts of those queues will be replaced.';
  }

  @override
  String get groupAlertsApply => 'Apply';

  @override
  String groupAlertsDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count queues',
      one: '1 queue',
    );
    return 'Alerts applied to $_temp0';
  }

  @override
  String get groupHistoryTitle => 'Group history';

  @override
  String get groupHistoryOpen => 'Group history';

  @override
  String get groupHistoryNoQueues => 'No queues in this group';

  @override
  String get groupHistoryNoQueuesHint =>
      'Add queues to the group to see the combined history.';

  @override
  String groupHistoryTruncated(int limit, String queues) {
    return 'Showing only the $limit most recent records of each queue. Queues with truncated history: $queues.';
  }

  @override
  String groupHistoryShowMore(int shown, int total) {
    return 'Show more ($shown of $total)';
  }

  @override
  String historyQueueOrigin(String name) {
    return 'Queue: $name';
  }

  @override
  String get colQueue => 'Queue';

  @override
  String infoButtonSemantics(String name) {
    return 'About this indicator: $name';
  }

  @override
  String get infoWhat => 'What it is';

  @override
  String get infoHow => 'How it is calculated';

  @override
  String get infoData => 'Data used';

  @override
  String get infoUse => 'What it is for';

  @override
  String get infoClose => 'Close';

  @override
  String get attColService => 'Avg. time';

  @override
  String get attColDeviation => 'Deviation';

  @override
  String get attColRate => 'Served/h';

  @override
  String get attColIdle => 'Idle';

  @override
  String attInsufficientNote(int samples) {
    return '— means not enough data (fewer than $samples served or a short window).';
  }

  @override
  String attRowSpoken(
    String name,
    int served,
    String service,
    String deviation,
    String rate,
    String idle,
    int noShow,
    String rating,
  ) {
    return '$name. $served served, average time $service, deviation $deviation, $rate served per hour, idle $idle, $noShow no-shows, rating $rating';
  }

  @override
  String get attChartTitleHour => 'Served by hour of day';

  @override
  String get attChartTitleShift => 'Served by shift';

  @override
  String get attChartModeHour => 'Hour';

  @override
  String get attChartModeShift => 'Shift';

  @override
  String get attChartOperatorLabel => 'Chart attendant';

  @override
  String get attChartAll => 'All attendants';

  @override
  String get attChartEmpty => 'No completed service for this chart.';

  @override
  String attChartPeak(String label, int count) {
    return 'Most served: $label ($count)';
  }

  @override
  String attChartSemantics(String summary) {
    return 'Served chart. $summary';
  }

  @override
  String get attShiftMorning => 'Morning (6am–12pm)';

  @override
  String get attShiftAfternoon => 'Afternoon (12pm–6pm)';

  @override
  String get attShiftNight => 'Night (6pm–6am)';

  @override
  String get csvDeviationPct => 'deviation vs average (%)';

  @override
  String get csvRatePerHour => 'served per hour (activity window)';

  @override
  String get csvIdlePct => 'idle (%)';

  @override
  String get abandonTitle => 'Abandonment';

  @override
  String get abandonSubtitle =>
      'People who joined and left before being served. Automatic removals (expiry and closing) are not counted.';

  @override
  String abandonBand(int start, int end) {
    return '$start–$end min';
  }

  @override
  String abandonBandOpen(int start) {
    return '$start+ min';
  }

  @override
  String get abandonWaitTitle => 'Rate by wait band';

  @override
  String get abandonWaitHint =>
      'Abandonment per 10 min of waiting, among those who reached each band.';

  @override
  String abandonWaitEmpty(int min) {
    return 'Not enough data: each band needs at least $min people to show a rate.';
  }

  @override
  String abandonBarSpoken(String band, int pct) {
    return '$band: $pct% per 10 min';
  }

  @override
  String abandonBarNoData(String band) {
    return '$band: not enough data';
  }

  @override
  String abandonInflectionFound(String band, int limit) {
    return 'Inflection point: from $band on, abandonment exceeds $limit% per 10 min.';
  }

  @override
  String abandonInflectionNone(int limit) {
    return 'No band exceeds the $limit% per 10 min limit.';
  }

  @override
  String get abandonEstimateTitle => 'Rate by estimate shown';

  @override
  String get abandonEstimateHint =>
      'Share who left according to the estimate the customer saw when joining.';

  @override
  String get abandonEstimateEmpty =>
      'No records with the estimate shown at joining yet. History from before the update that stores the estimate does not have this data.';

  @override
  String abandonEstimateBarSpoken(String band, int pct) {
    return 'Estimate $band: $pct% left';
  }

  @override
  String abandonEstimateBarNoData(String band) {
    return 'Estimate $band: not enough data';
  }

  @override
  String get estimateAccuracyTitle => 'Estimate accuracy';

  @override
  String estimateAccuracyMean(String value, int samples) {
    return 'Actual wait minus estimate: $value min on average ($samples served)';
  }

  @override
  String estimateAccuracyAbs(String value) {
    return 'Mean absolute error: $value min';
  }

  @override
  String get estimateAccuracyHint =>
      'Positive: the wait was longer than promised.';

  @override
  String estimateAccuracyNone(int min) {
    return 'Not enough data: $min served entries with a stored estimate are needed.';
  }

  @override
  String get abandonHourTitle => 'Abandonment by arrival hour';

  @override
  String get abandonHourRateLabel => 'Rate';

  @override
  String get abandonHourCountLabel => 'Left';

  @override
  String abandonHourEmpty(int min) {
    return 'Not enough data: each hour needs at least $min people to show a rate.';
  }

  @override
  String abandonHourPeak(String hour, int pct, int left, int total) {
    return 'Highest rate at $hour: $pct% ($left of $total)';
  }

  @override
  String abandonHourSpoken(String hour, int pct, int left, int total) {
    return '$hour: $pct% left ($left of $total)';
  }

  @override
  String abandonHourNoRate(String hour, int left, int total) {
    return '$hour: $left of $total, rate with not enough data';
  }

  @override
  String get capacityCardTitle => 'Possible capacity shortage';

  @override
  String capacityCardBody(String hours, int wait, int rate) {
    return 'At these hours the average wait is $wait min or more and $rate% or more leave: $hours. Consider adding staff.';
  }

  @override
  String get capacityCardNone => 'No critical hours in the period';

  @override
  String get csvWaitBand => 'wait band (min)';

  @override
  String get csvEstimateBand => 'estimate band (min)';

  @override
  String get csvAtRisk => 'reached the band';

  @override
  String get csvAbandonRatePct => 'abandonment (%)';

  @override
  String get csvAbandonPer10Pct => 'abandonment per 10 min (%)';

  @override
  String get csvInflection => 'inflection point';

  @override
  String get csvCapacityHours => 'hours with capacity signal';

  @override
  String get csvEstimateErrorMin => 'mean estimate error (min)';

  @override
  String get csvEstimateAbsErrorMin => 'mean absolute estimate error (min)';

  @override
  String get biNameAttendantThroughput => 'Served by hour and shift';

  @override
  String get biWhatAttendantThroughput =>
      'How many services each attendant completed, spread by hour of day (0 to 23) and by shift (morning 6am–12pm, afternoon 12pm–6pm, night 6pm–6am).';

  @override
  String get biHowAttendantThroughput =>
      'Counts served entries grouped by the moment they finished (or were called, if the finish is missing), converted to São Paulo time. No-shows and abandonments are not counted.';

  @override
  String get biDataAttendantThroughput =>
      'Result, finish time, call time and who called.';

  @override
  String get biUseAttendantThroughput =>
      'See at which hours and shifts each person concentrates work and plan schedules.';

  @override
  String get biNameAttendantService => 'Average service time';

  @override
  String get biWhatAttendantService =>
      'How long, on average, the attendant takes between calling the customer and finishing the service.';

  @override
  String biHowAttendantService(int min) {
    return 'Average of (finish − call) for served entries. With fewer than $min valid samples the value is not shown (—).';
  }

  @override
  String get biDataAttendantService =>
      'Call time, finish time and the “served” result.';

  @override
  String get biUseAttendantService =>
      'Know each person’s real pace and adjust the average time configured for the queue.';

  @override
  String get biNameAttendantDeviation => 'Deviation from average';

  @override
  String get biWhatAttendantDeviation =>
      'How far the attendant’s average time is from everyone’s average in the selected scope. Negative means faster.';

  @override
  String biHowAttendantDeviation(int min) {
    return '(attendant average − scope average) ÷ scope average × 100. The scope average is weighted by samples. Only attendants with at least $min samples take part; others show —.';
  }

  @override
  String get biDataAttendantDeviation =>
      'Service time of each attendant’s served entries.';

  @override
  String get biUseAttendantDeviation =>
      'Spot who differs from the norm, for training or reviewing the average time. It does not measure quality: a longer service may be more complex.';

  @override
  String get biNameAttendantRate => 'Served per hour in the activity window';

  @override
  String get biWhatAttendantRate =>
      'The attendant’s pace within the window in which they worked that day. Breaks and gaps between services are inside the window; it is not hours actually worked.';

  @override
  String biHowAttendantRate(int min, int window) {
    return 'Per day: served ÷ hours between the first call and the last finish. A day counts only with $min or more services and a window of at least $window min. The value shown adds services and hours of valid days.';
  }

  @override
  String get biDataAttendantRate =>
      'Call time, finish time, result and who called.';

  @override
  String get biUseAttendantRate =>
      'Compare productivity without the bias of people who worked few hours.';

  @override
  String get biNameAttendantIdle => 'Idle time';

  @override
  String get biWhatAttendantIdle =>
      'Share of time the attendant stood idle while people were waiting.';

  @override
  String biHowAttendantIdle(int cap, int min) {
    return 'Sum of the gaps between the end of one service and the next call, ÷ time observed in the day. A gap counts only if the next customer was already in the queue, is greater than zero and at most $cap min (longer is assumed to be a break) and falls on the same day. Shown only with at least $min completed services.';
  }

  @override
  String get biDataAttendantIdle =>
      'Queue join time, call time and finish time. It is an approximation: the history does not store the queue size at each moment.';

  @override
  String get biUseAttendantIdle =>
      'Find time lost between services (slow switching, distraction), separated from an empty queue.';

  @override
  String get biNameAbandonWait => 'Abandonment by wait band';

  @override
  String get biWhatAbandonWait =>
      'Of those who waited at least up to a point, the fraction who left in that band.';

  @override
  String biHowAbandonWait(String bands, int min) {
    return 'Bands of $bands min. In each band: people who left in the band ÷ people who reached it (including those who waited longer and were served). Bars show the rate per 10 min (capped at 100%; bands narrower than 5 min use 5 min as the divisor), so bands of different widths can be compared. A band with fewer than $min people shows no rate.';
  }

  @override
  String get biDataAbandonWait =>
      'Result, join, call and finish times, and exit reason. System removals (expired or closed) are excluded. People still in the queue do not appear, so recent long waits may be under-represented.';

  @override
  String get biUseAbandonWait =>
      'Show from which wait the customer starts to leave.';

  @override
  String get biNameAbandonInflection => 'Inflection point';

  @override
  String get biWhatAbandonInflection =>
      'The first wait band in which abandonment goes beyond the tolerable.';

  @override
  String biHowAbandonInflection(int limit) {
    return 'First band, in ascending order, with more than $limit% abandonment per 10 minutes. Bands without a rate (not enough data) are skipped. If none passes, there is no inflection point.';
  }

  @override
  String get biDataAbandonInflection => 'The same rate by wait band.';

  @override
  String get biUseAbandonInflection =>
      'Define the maximum wait target and the warning text shown to the customer.';

  @override
  String get biNameAbandonEstimate => 'Abandonment by estimate shown';

  @override
  String get biWhatAbandonEstimate =>
      'The abandonment rate split by the wait estimate the customer saw when joining.';

  @override
  String biHowAbandonEstimate(String bands, int min) {
    return 'Groups by estimate ($bands min): people who left ÷ total people who saw that estimate. A band with fewer than $min people shows no rate.';
  }

  @override
  String get biDataAbandonEstimate =>
      'Estimate stored at joining and result. Records from before the update that stores the estimate lack the field and are excluded.';

  @override
  String get biUseAbandonEstimate =>
      'Learn whether promising a long wait drives customers away, and whether to show the estimate differently.';

  @override
  String get biNameEstimateAccuracy => 'Estimate accuracy';

  @override
  String get biWhatEstimateAccuracy =>
      'How far off the estimate shown to the customer was, in minutes.';

  @override
  String biHowEstimateAccuracy(int min) {
    return 'Average of (actual wait − estimate) for served and no-show entries. Positive: the wait was longer than promised. It also shows the mean absolute error, which keeps positive and negative errors from cancelling out. Fewer than $min samples: not calculated.';
  }

  @override
  String get biDataEstimateAccuracy =>
      'Estimate stored at joining, join time and call time. Records from before the estimate was stored are excluded.';

  @override
  String get biUseEstimateAccuracy =>
      'Assess whether the configured average time reflects reality and when to adjust it.';

  @override
  String get biNameAbandonHour => 'Abandonment by arrival hour';

  @override
  String get biWhatAbandonHour =>
      'The rate and number of abandonments by the hour the person joined the queue.';

  @override
  String biHowAbandonHour(int min) {
    return 'Groups by join hour (São Paulo time). Rate = people who left ÷ (served + no-show + left). An hour with fewer than $min people shows no rate, but the count still appears.';
  }

  @override
  String get biDataAbandonHour =>
      'Result, join time, wait and exit reason. System removals are excluded.';

  @override
  String get biUseAbandonHour => 'Locate problematic peak hours.';

  @override
  String get biNameCapacitySignal => 'Capacity signal';

  @override
  String get biWhatCapacitySignal =>
      'The hours in which the queue seems undersized.';

  @override
  String biHowCapacitySignal(int wait, int rate) {
    return 'Hours with an average wait of $wait min or more and an abandonment rate of $rate% or more. Hours without a rate (not enough data) are not included.';
  }

  @override
  String get biDataCapacitySignal =>
      'Abandonment by arrival hour and the average wait of each hour.';

  @override
  String get biUseCapacitySignal =>
      'Indicate where to add attendants or adjust schedules.';

  @override
  String abandonBarCounts(int left, int total) {
    return '$left of $total left';
  }

  @override
  String abandonScopeQueue(String name) {
    return 'Queue: $name (filter from the By attendant section)';
  }

  @override
  String get goalsTitle => 'Service goals';

  @override
  String get goalsNone => 'No goals set';

  @override
  String goalsValueWait(int min) {
    return 'Wait up to $min min';
  }

  @override
  String goalsValueService(int min) {
    return 'Service up to $min min';
  }

  @override
  String goalsValueTarget(int pct) {
    return 'target $pct%';
  }

  @override
  String get goalsDialogHint =>
      'Set the acceptable time and the share of people who should meet the goal. Leave blank what you do not want to measure.';

  @override
  String get goalsWaitLabel => 'Maximum wait (min)';

  @override
  String get goalsServiceLabel => 'Maximum service time (min)';

  @override
  String get goalsTargetLabel => 'Compliance target (%)';

  @override
  String goalsTargetHint(int pct) {
    return 'Default $pct';
  }

  @override
  String goalsErrRange(int min, int max) {
    return 'Enter $min to $max minutes.';
  }

  @override
  String goalsErrTarget(int min, int max) {
    return 'Enter $min to $max%.';
  }

  @override
  String get goalsErrNone => 'Set at least one goal: wait or service time.';

  @override
  String get goalsRemove => 'Remove goals';

  @override
  String get goalRiskTitle => 'Wait goal at risk';

  @override
  String goalRiskBody(int waiting, int est, int goal) {
    return 'With $waiting in the queue, the estimated wait is $est min, above the $goal min goal.';
  }

  @override
  String get goalRiskAction =>
      'Suggestion: bring in another attendant or open another counter.';

  @override
  String get goalsSectionTitle => 'Goals';

  @override
  String get goalsSectionSubtitle =>
      'How well the goals set on each queue were met, for the chosen period and scope.';

  @override
  String goalsQueuesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Goals from $count queues in scope',
      one: 'Goal from 1 queue in scope',
    );
    return '$_temp0';
  }

  @override
  String get goalsWaitCardTitle => 'Wait within goal';

  @override
  String get goalsServiceCardTitle => 'Service within goal';

  @override
  String goalsTargetLine(int pct) {
    return 'Target: $pct% within the limit';
  }

  @override
  String goalsCounts(int ok, int total) {
    return '$ok of $total within the limit';
  }

  @override
  String get goalsMet => 'Met';

  @override
  String get goalsNotMet => 'Not met';

  @override
  String goalsSmallSample(int min) {
    return 'Small sample: fewer than $min evaluated.';
  }

  @override
  String get goalsNoSamples => 'Nothing in the period to evaluate this goal.';

  @override
  String get goalsNotSet => 'No queue in scope has this goal.';

  @override
  String get goalsDailyTitle => 'Compliance by day';

  @override
  String goalsDailySemantics(int days, int missed) {
    return '$days days evaluated, $missed below target';
  }

  @override
  String get goalsMissedTitle => 'Periods when the goal was not met';

  @override
  String goalsMissedNone(int min) {
    return 'No day or hour below target with at least $min evaluated.';
  }

  @override
  String get goalsKindWait => 'Wait';

  @override
  String get goalsKindService => 'Service';

  @override
  String goalsMissedDayRow(
    String kind,
    String day,
    int pct,
    int ok,
    int total,
    int target,
  ) {
    return '$kind, $day: $pct% ($ok of $total), target $target%';
  }

  @override
  String goalsMissedHoursRow(String kind, String hours) {
    return '$kind, hours below target: $hours';
  }

  @override
  String goalsMissedMore(int count) {
    return 'and $count more days';
  }

  @override
  String goalsWorstWait(int over, String day) {
    return 'Worst wait violation: $over min over the goal, on $day.';
  }

  @override
  String goalsWorstService(int over, String day) {
    return 'Worst service violation: $over min over the goal, on $day.';
  }

  @override
  String get goalsNoViolation => 'No violations in the period.';

  @override
  String get goalsCtaTitle => 'Set service goals';

  @override
  String get goalsCtaBody =>
      'No queue in this scope has goals. Open the queue, go to Settings and use Service goals to track compliance here.';

  @override
  String get staffTitle => 'Staff planning';

  @override
  String get staffSubtitle =>
      'How many attendants each day and hour require, compared with who actually served.';

  @override
  String staffServiceTime(String min, int samples) {
    return 'Average service time: $min min ($samples services)';
  }

  @override
  String staffServiceNone(int min) {
    return 'Average time unavailable: at least $min completed services are needed.';
  }

  @override
  String staffOccupancy(int pct) {
    return 'Target occupancy: $pct%';
  }

  @override
  String staffCoverage(int days) {
    return 'Basis: $days days of data';
  }

  @override
  String get staffModeRequired => 'Recommended';

  @override
  String get staffModeObserved => 'Observed';

  @override
  String get staffModeGap => 'Difference';

  @override
  String get staffGridTitle => 'Attendants by day and hour';

  @override
  String staffHintRequired(int pct) {
    return 'Attendants recommended to absorb the average demand at $pct% target occupancy.';
  }

  @override
  String get staffHintObserved =>
      'Average number of distinct attendants who served in each day and hour.';

  @override
  String get staffHintGap =>
      'Recommended minus observed. Positive: understaffed. Negative: spare capacity.';

  @override
  String get staffLegendDeficit => 'Short';

  @override
  String get staffLegendOk => 'Balanced';

  @override
  String get staffLegendSurplus => 'Spare';

  @override
  String staffCellSpoken(
    String day,
    String hour,
    int required,
    String observed,
  ) {
    return '$day $hour: recommended $required, observed $observed';
  }

  @override
  String staffGridSpoken(String mode, String top) {
    return 'Attendants grid by weekday and hour, $mode mode. $top';
  }

  @override
  String get staffTopTitle => 'Largest shortfalls';

  @override
  String staffTopRow(String day, String hour, int required, String observed) {
    return '$day $hour: needs $required, has $observed';
  }

  @override
  String get staffTopNone =>
      'No shortfall: the observed team covers the recommended demand.';

  @override
  String get staffNoData => 'No arrivals in the period to size the team.';

  @override
  String get staffSeasonTitle => 'Weekly volume and seasonality';

  @override
  String staffSeasonInsufficient(int need, int have) {
    return 'Not enough data: at least $need complete weeks with data are needed ($have so far).';
  }

  @override
  String staffTrendUp(String pct) {
    return 'Upward trend: about +$pct% per week.';
  }

  @override
  String staffTrendDown(String pct) {
    return 'Downward trend: about $pct% per week.';
  }

  @override
  String staffTrendStable(int pct) {
    return 'Stable volume: change below $pct% per week.';
  }

  @override
  String staffWeekSpoken(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count arrivals',
      one: '1 arrival',
    );
    return 'Week of $date: $_temp0';
  }

  @override
  String get staffRecurringTitle => 'Recurring pattern';

  @override
  String staffRecurringRow(String day, String hour, int weeks, int total) {
    return '$day $hour: among the busiest in $weeks of $total weeks';
  }

  @override
  String staffRecurringNone(int pct) {
    return 'No hour repeats among the busiest in at least $pct% of the weeks.';
  }

  @override
  String get csvGoalIndicator => 'indicator';

  @override
  String get csvEvaluated => 'evaluated';

  @override
  String get csvWithinLimit => 'within limit';

  @override
  String get csvPctWithinLimit => '% within limit';

  @override
  String get csvTargetPct => 'target %';

  @override
  String get csvGoalMet => 'goal met';

  @override
  String get csvWorstOverMin => 'worst violation (min)';

  @override
  String get csvWorstDay => 'worst violation day';

  @override
  String get csvMissedDays => 'days below target';

  @override
  String get csvMissedHours => 'hours below target';

  @override
  String get csvArrivalsPerHour => 'arrivals per hour';

  @override
  String get csvRequiredStaff => 'recommended attendants';

  @override
  String get csvObservedStaff => 'observed attendants';

  @override
  String get csvGapStaff => 'difference';

  @override
  String get csvWeekStart => 'week start';

  @override
  String get csvTrendPct => 'trend (% of mean per week)';

  @override
  String get csvRecurringWeeks => 'weeks among the busiest';

  @override
  String get csvOccupancyPct => 'target occupancy %';

  @override
  String get csvCoverageDays => 'days of data';

  @override
  String get biNameGoalWait => 'Wait within goal';

  @override
  String get biWhatGoalWait =>
      'The share of services where the person waited up to the wait limit set on the queue.';

  @override
  String biHowGoalWait(int min) {
    return 'Compares the wait (call time minus join time) of each served and no-show person with the wait goal. Someone who left only counts if they waited longer than the goal, as a miss; leaving below the goal and system removals are excluded. Percentage = within limit ÷ evaluated. The goal is met when the percentage reaches the target (default 80%). With several queues, each person is compared with their own queue goal and the target shown is the average weighted by evaluated people. Below $min evaluated, the result is flagged as a small sample.';
  }

  @override
  String get biDataGoalWait =>
      'Result, join, call and exit (when leaving) times and the queue goals. No phone numbers.';

  @override
  String get biUseGoalWait =>
      'Know whether service is within the promised time and when it fails.';

  @override
  String get biNameGoalService => 'Service within goal';

  @override
  String get biWhatGoalService =>
      'The share of completed services that took up to the maximum time set on the queue.';

  @override
  String biHowGoalService(int min) {
    return 'Completed (served) services only. Compares the duration (end minus call time) with the service goal. Percentage = within limit ÷ evaluated; the goal is met when it reaches the target. No-shows and people who left are excluded. Below $min evaluated, the result is flagged as a small sample.';
  }

  @override
  String get biDataGoalService =>
      'Result, call and end times and the queue goals.';

  @override
  String get biUseGoalService =>
      'Check whether services fit the expected time and find slow days and hours.';

  @override
  String get biNameGoalMissed => 'Periods when the goal was not met';

  @override
  String get biWhatGoalMissed =>
      'Days and hours of day when compliance fell below target, and the worst violation.';

  @override
  String biHowGoalMissed(int min) {
    return 'Groups evaluated people by day and by hour of day (São Paulo time). Lists the days and hours with at least $min evaluated and a percentage below target. The worst violation is the largest excess, in minutes, over the wait or service limit. Days and hours with fewer evaluated are not listed.';
  }

  @override
  String get biDataGoalMissed =>
      'The same as the wait and service within goal indicators.';

  @override
  String get biUseGoalMissed =>
      'Find when the goal fails repeatedly and reinforce the team in those periods.';

  @override
  String get biNameStaffingService => 'Average service time';

  @override
  String get biWhatStaffingService =>
      'The average duration of completed services, used to estimate how many attendants are needed.';

  @override
  String biHowStaffingService(int min) {
    return 'Average of end minus call time of completed (served) services in the scope and period. With fewer than $min services it is not computed and the attendant recommendation is unavailable.';
  }

  @override
  String get biDataStaffingService => 'Result, call and end times.';

  @override
  String get biUseStaffingService =>
      'Serve as the basis for the recommended attendants calculation.';

  @override
  String get biNameStaffingRequired => 'Recommended attendants';

  @override
  String get biWhatStaffingRequired =>
      'How many attendants each weekday and hour require to absorb the average demand.';

  @override
  String biHowStaffingRequired(int pct) {
    return 'Arrivals per hour = arrivals on that weekday and hour ÷ number of times that weekday occurs between the first and last day with data (includes people who left and no-shows). Recommended = round up (arrivals per hour × average service time in hours ÷ $pct% target occupancy). Unavailable without an average service time.';
  }

  @override
  String get biDataStaffingRequired =>
      'Join time of everyone, result, call and end times.';

  @override
  String get biUseStaffingRequired =>
      'Build schedules: see on which days and hours the team needs to be larger.';

  @override
  String get biNameStaffingObserved => 'Observed attendants';

  @override
  String get biWhatStaffingObserved =>
      'How many distinct attendants actually served on each weekday and hour.';

  @override
  String get biHowStaffingObserved =>
      'For each date and hour, counts the distinct attendants with a service in progress, from call to end (long services count in every hour they span). Sums by weekday and hour and divides by the same number of weekday occurrences used for arrivals. The owner and records without an attendant count as one attendant.';

  @override
  String get biDataStaffingObserved =>
      'Attendant, call and end times, result (served or no-show).';

  @override
  String get biUseStaffingObserved =>
      'Compare the team that actually worked with the recommended one.';

  @override
  String get biNameStaffingGap => 'Shortfall and spare capacity';

  @override
  String get biWhatStaffingGap =>
      'The difference between recommended and observed attendants on each day and hour.';

  @override
  String biHowStaffingGap(int n) {
    return 'Difference = recommended minus observed. Positive is a shortfall (understaffed); negative is spare capacity. The list shows the $n largest positive differences, breaking ties by recommended, day and hour.';
  }

  @override
  String get biDataStaffingGap =>
      'The same as recommended and observed attendants.';

  @override
  String get biUseStaffingGap =>
      'Prioritize where to reinforce the team and where capacity is spare.';

  @override
  String get biNameSeasonVolume => 'Weekly volume and trend';

  @override
  String get biWhatSeasonVolume =>
      'How many people joined the queue in each of the last weeks and where the volume is heading.';

  @override
  String biHowSeasonVolume(int weeks, int band, int min) {
    return 'Counts arrivals (including people who left and no-shows) per week, Monday to Sunday (São Paulo time), over the last $weeks complete weeks, starting at the first week with data; the week in progress is excluded. The trend is the slope of a line fitted to the weekly volumes, as % of the weekly mean per week; below $band% is considered stable. With fewer than $min weeks, it shows insufficient data.';
  }

  @override
  String get biDataSeasonVolume =>
      'Join time of everyone. Uses all the loaded history of the scope, not only the chosen period.';

  @override
  String get biUseSeasonVolume =>
      'Plan staff and space for the coming periods.';

  @override
  String get biNameSeasonPattern => 'Recurring pattern';

  @override
  String get biWhatSeasonPattern =>
      'Weekdays and hours that repeat among the busiest, week after week.';

  @override
  String biHowSeasonPattern(int top, int pct, int min) {
    return 'In each observed week, takes the $top cells (weekday × hour) with the most arrivals. A cell is recurring when it appears in that group in at least $pct% of the observed weeks. Requires at least $min weeks.';
  }

  @override
  String get biDataSeasonPattern => 'Join time of everyone.';

  @override
  String get biUseSeasonPattern =>
      'Know which times are always busy, not by chance.';
}
