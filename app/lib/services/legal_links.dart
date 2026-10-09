import 'package:url_launcher/url_launcher.dart';

import 'join_url.dart';

const privacyPath = '/privacidade';
const termsPath = '/termos';

Uri get privacyUrl => Uri.https(joinHost, privacyPath);
Uri get termsUrl => Uri.https(joinHost, termsPath);

Future<bool> openLegalUrl(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);
