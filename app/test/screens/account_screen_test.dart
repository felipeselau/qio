import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/screens/account_screen.dart';
import 'package:qio_app/widgets/qio_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_auth.dart';
import '../helpers/pump_app.dart';

const tall = Size(390, 1400);

Future<void> tick(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows owner profile, queue count and member since', (
    tester,
  ) async {
    final auth = FakeAuthService(
      user: FakeUser(displayName: 'Maria', email: 'maria@qio.app'),
    );
    await pumpApp(
      tester,
      AccountScreen(
        auth: auth,
        loadOwner: (_) async => {
          'name': 'Maria Souza',
          'businessName': 'Padaria Sol',
        },
        loadQueueCount: (_) async => 4,
      ),
      size: tall,
    );
    await tick(tester);
    expect(find.text('Minha conta'), findsOneWidget);
    expect(find.text('Maria Souza'), findsOneWidget);
    expect(find.text('Negócio: Padaria Sol'), findsOneWidget);
    expect(find.text('maria@qio.app'), findsOneWidget);
    expect(find.text('Filas criadas'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('10/03/2025'), findsOneWidget);
  });

  testWidgets('falls back to auth display name when owner doc is missing', (
    tester,
  ) async {
    final auth = FakeAuthService(user: FakeUser(displayName: 'Joao'));
    await pumpApp(
      tester,
      AccountScreen(
        auth: auth,
        loadOwner: (_) async => null,
        loadQueueCount: (_) async => null,
      ),
      size: tall,
    );
    await tick(tester);
    expect(find.text('Joao'), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('shows skeleton while the owner doc loads', (tester) async {
    final auth = FakeAuthService(user: FakeUser());
    await pumpApp(
      tester,
      AccountScreen(
        auth: auth,
        loadOwner: (_) => Future.delayed(
          const Duration(seconds: 1),
          () => <String, dynamic>{'name': 'Lenta'},
        ),
        loadQueueCount: (_) async => 1,
      ),
      size: tall,
    );
    expect(find.text('Lenta'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Lenta'), findsOneWidget);
  });

  testWidgets('appearance and language cards render their options', (
    tester,
  ) async {
    await pumpApp(
      tester,
      AccountScreen(
        auth: FakeAuthService(user: FakeUser()),
        loadOwner: (_) async => null,
        loadQueueCount: (_) async => 0,
      ),
      size: tall,
    );
    await tick(tester);
    expect(find.text('Aparência'), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Escuro'), findsOneWidget);
  });

  testWidgets('sign out calls the auth service', (tester) async {
    final auth = FakeAuthService(user: FakeUser());
    await pumpApp(
      tester,
      AccountScreen(
        auth: auth,
        loadOwner: (_) async => null,
        loadQueueCount: (_) async => 0,
      ),
      size: tall,
    );
    await tick(tester);
    await tester.tap(find.widgetWithText(QioButton, 'Sair da conta'));
    await tick(tester);
    expect(auth.calls, ['signOut']);
  });

  testWidgets('sign out failure shows an error snackbar', (tester) async {
    final auth = FakeAuthService(
      user: FakeUser(),
      signOutError: Exception('x'),
    );
    await pumpApp(
      tester,
      AccountScreen(
        auth: auth,
        loadOwner: (_) async => null,
        loadQueueCount: (_) async => 0,
      ),
      size: tall,
    );
    await tick(tester);
    await tester.tap(find.widgetWithText(QioButton, 'Sair da conta'));
    await tick(tester);
    expect(find.text('Não foi possível sair da conta.'), findsOneWidget);
  });
}
