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
    return '$count time slots';
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
}
