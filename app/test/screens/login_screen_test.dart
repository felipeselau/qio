import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/screens/login_screen.dart';
import 'package:qio_app/widgets/qio_button.dart';

import '../helpers/fake_auth.dart';
import '../helpers/pump_app.dart';

Future<void> settle(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 300));

Finder primary(String label) => find.widgetWithText(QioButton, label);

void main() {
  testWidgets('empty form shows required-field errors and does not submit', (
    tester,
  ) async {
    final auth = FakeAuthService();
    await pumpApp(tester, LoginScreen(auth: auth));
    await tester.tap(primary('Entrar'));
    await settle(tester);
    expect(find.text('Informe o email'), findsOneWidget);
    expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
    expect(auth.calls, isEmpty);
  });

  testWidgets('short password is rejected', (tester) async {
    final auth = FakeAuthService();
    await pumpApp(tester, LoginScreen(auth: auth));
    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(primary('Entrar'));
    await settle(tester);
    expect(find.text('Mínimo 6 caracteres'), findsOneWidget);
    expect(auth.calls, isEmpty);
  });

  testWidgets('valid form calls signInWithEmail with trimmed email', (
    tester,
  ) async {
    final auth = FakeAuthService();
    await pumpApp(tester, LoginScreen(auth: auth));
    await tester.enterText(find.byType(TextFormField).at(0), ' a@b.com ');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.tap(primary('Entrar'));
    await settle(tester);
    expect(auth.calls, ['signIn:a@b.com:secret1']);
  });

  testWidgets('auth failure shows the localized error', (tester) async {
    final auth = FakeAuthService(
      error: FirebaseAuthException(code: 'wrong-password'),
    );
    await pumpApp(tester, LoginScreen(auth: auth));
    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.tap(primary('Entrar'));
    await settle(tester);
    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
  });

  testWidgets('unknown error shows the generic message', (tester) async {
    final auth = FakeAuthService(error: Exception('boom'));
    await pumpApp(tester, LoginScreen(auth: auth));
    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret1');
    await tester.tap(primary('Entrar'));
    await settle(tester);
    expect(
      find.text('Não foi possível entrar. Tente novamente.'),
      findsOneWidget,
    );
  });

  testWidgets('sign-up mode requires a name and calls signUpWithEmail', (
    tester,
  ) async {
    final auth = FakeAuthService();
    await pumpApp(tester, LoginScreen(auth: auth));
    await tester.tap(find.widgetWithText(TextButton, 'Criar conta'));
    await settle(tester);
    expect(find.byType(TextFormField), findsNWidgets(3));
    await tester.tap(primary('Criar conta'));
    await settle(tester);
    expect(find.text('Informe seu nome'), findsOneWidget);
    expect(auth.calls, isEmpty);

    await tester.enterText(find.byType(TextFormField).at(0), 'Ana');
    await tester.enterText(find.byType(TextFormField).at(1), 'a@b.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'secret1');
    await tester.tap(primary('Criar conta'));
    await settle(tester);
    expect(auth.calls, ['signUp:Ana:a@b.com']);
  });

  testWidgets('forgot password without email asks for it', (tester) async {
    final auth = FakeAuthService();
    await pumpApp(tester, LoginScreen(auth: auth));
    await tester.tap(find.text('Esqueci a senha'));
    await settle(tester);
    expect(
      find.text('Informe seu e-mail para recuperar a senha'),
      findsOneWidget,
    );
    expect(auth.calls, isEmpty);
  });

  testWidgets('forgot password with email sends reset', (tester) async {
    final auth = FakeAuthService();
    await pumpApp(tester, LoginScreen(auth: auth));
    await tester.enterText(find.byType(TextFormField).at(0), 'a@b.com');
    await tester.tap(find.text('Esqueci a senha'));
    await settle(tester);
    expect(auth.calls, ['reset:a@b.com']);
    expect(
      find.text(
        'Se houver uma conta com esse e-mail, enviamos um link para redefinir a senha.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('renders in English dark at 320 width', (tester) async {
    await pumpApp(
      tester,
      LoginScreen(auth: FakeAuthService()),
      locale: const Locale('en'),
      themeMode: ThemeMode.dark,
      size: const Size(320, 640),
    );
    expect(find.text('Sign in'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
