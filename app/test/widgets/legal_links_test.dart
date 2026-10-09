import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/screens/account_screen.dart';
import 'package:qio_app/screens/login_screen.dart';
import 'package:qio_app/services/legal_links.dart';
import 'package:qio_app/widgets/legal_links.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_auth.dart';
import '../helpers/pump_app.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('urls point to the public pages', () {
    expect(privacyUrl.toString(), 'https://qio.web.app/privacidade');
    expect(termsUrl.toString(), 'https://qio.web.app/termos');
  });

  testWidgets('opens privacy and terms urls', (tester) async {
    final opened = <Uri>[];
    await pumpApp(
      tester,
      Scaffold(
        body: LegalLinks(
          onOpen: (uri) async {
            opened.add(uri);
            return true;
          },
        ),
      ),
    );
    await tester.tap(find.text('Política de privacidade'));
    await tester.tap(find.text('Termos de uso'));
    expect(opened, [privacyUrl, termsUrl]);
  });

  testWidgets('localizes labels', (tester) async {
    await pumpApp(
      tester,
      const Scaffold(body: LegalLinks()),
      locale: const Locale('en'),
    );
    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.text('Terms of use'), findsOneWidget);
  });

  testWidgets('login screen shows the links', (tester) async {
    await pumpApp(tester, LoginScreen(auth: FakeAuthService()));
    expect(find.text('Política de privacidade'), findsOneWidget);
    expect(find.text('Termos de uso'), findsOneWidget);
  });

  testWidgets('account screen shows the links', (tester) async {
    await pumpApp(
      tester,
      AccountScreen(
        auth: FakeAuthService(user: FakeUser(displayName: 'Maria')),
        loadOwner: (_) async => null,
        loadQueueCount: (_) async => 0,
      ),
      size: const Size(390, 1400),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Política de privacidade'), findsOneWidget);
    expect(find.text('Termos de uso'), findsOneWidget);
  });
}
