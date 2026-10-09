import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qio_app/screens/account_screen.dart';
import 'package:qio_app/services/delete_service.dart';
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

  testWidgets('shows the customer data entry only for owners with queues', (
    tester,
  ) async {
    final auth = FakeAuthService(user: FakeUser(displayName: 'Maria'));
    await pumpApp(
      tester,
      AccountScreen(
        auth: auth,
        loadOwner: (_) async => null,
        loadQueueCount: (_) async => 2,
      ),
      size: tall,
    );
    await tick(tester);
    expect(find.text('Dados de um cliente'), findsOneWidget);
    await tester.tap(find.text('Dados de um cliente'));
    await tester.pumpAndSettle();
    expect(find.text('Telefone do cliente'), findsOneWidget);
  });

  testWidgets('hides the customer data entry without queues', (tester) async {
    final auth = FakeAuthService(user: FakeUser(displayName: 'Maria'));
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
    expect(find.text('Dados de um cliente'), findsNothing);
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

  group('excluir minha conta', () {
    late List<String> invoked;
    Object? failWith;

    DeleteService service() => DeleteService(
      invoker: (name, data) async {
        invoked.add(name);
        final err = failWith;
        if (err != null) throw err;
        return {'ok': true};
      },
    );

    setUp(() {
      invoked = [];
      failWith = null;
    });

    Future<void> open(WidgetTester tester, FakeAuthService auth) async {
      await pumpApp(
        tester,
        AccountScreen(
          auth: auth,
          loadOwner: (_) async => null,
          loadQueueCount: (_) async => 0,
          deleteService: service(),
        ),
        size: tall,
      );
      await tick(tester);
      final btn = find.widgetWithText(QioButton, 'Excluir minha conta');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tick(tester);
    }

    Finder confirmButton() =>
        find.widgetWithText(TextButton, 'Excluir definitivamente');

    testWidgets('botão fica desabilitado sem confirmação e senha', (
      tester,
    ) async {
      final auth = FakeAuthService(user: FakeUser());
      await open(tester, auth);
      expect(tester.widget<TextButton>(confirmButton()).onPressed, isNull);
      await tester.enterText(find.byType(TextField).first, 'excluir');
      await tester.pump();
      expect(tester.widget<TextButton>(confirmButton()).onPressed, isNull);
      await tester.enterText(find.byType(TextField).last, 'segredo');
      await tester.pump();
      expect(tester.widget<TextButton>(confirmButton()).onPressed, isNotNull);
    });

    testWidgets('aceita o e-mail, reautentica e chama a callable', (
      tester,
    ) async {
      final auth = FakeAuthService(user: FakeUser(email: 'dono@qio.app'));
      await open(tester, auth);
      await tester.enterText(find.byType(TextField).first, 'DONO@qio.app');
      await tester.enterText(find.byType(TextField).last, 'segredo');
      await tester.pump();
      await tester.tap(confirmButton());
      await tick(tester);
      expect(invoked, ['deleteAccount']);
      expect(auth.calls, ['reauth:password:segredo', 'signOut']);
    });

    testWidgets('conta Google reautentica com Google', (tester) async {
      final auth = FakeAuthService(user: FakeUser(), passwordProvider: false);
      await open(tester, auth);
      expect(find.byType(TextField), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'EXCLUIR');
      await tester.pump();
      await tester.tap(confirmButton());
      await tick(tester);
      expect(auth.calls, ['reauth:google', 'signOut']);
      expect(invoked, ['deleteAccount']);
    });

    testWidgets('falha na reautenticação não chama a callable', (tester) async {
      final auth = FakeAuthService(
        user: FakeUser(),
        reauthError: FirebaseAuthException(code: 'wrong-password'),
      );
      await open(tester, auth);
      await tester.enterText(find.byType(TextField).first, 'EXCLUIR');
      await tester.enterText(find.byType(TextField).last, 'errada');
      await tester.pump();
      await tester.tap(confirmButton());
      await tick(tester);
      expect(invoked, isEmpty);
      expect(auth.calls, ['reauth:password:errada']);
      expect(
        find.textContaining('Não foi possível confirmar sua identidade'),
        findsOneWidget,
      );
    });

    testWidgets('recent-login pede nova reautenticação', (tester) async {
      final auth = FakeAuthService(user: FakeUser());
      failWith = FirebaseException(
        plugin: 'cloud_functions',
        code: 'recent-login',
      );
      await open(tester, auth);
      await tester.enterText(find.byType(TextField).first, 'EXCLUIR');
      await tester.enterText(find.byType(TextField).last, 'segredo');
      await tester.pump();
      await tester.tap(confirmButton());
      await tick(tester);
      expect(
        find.textContaining('confirme sua identidade de novo'),
        findsOneWidget,
      );

      failWith = null;
      await tester.tap(confirmButton());
      await tick(tester);
      expect(auth.calls, [
        'reauth:password:segredo',
        'reauth:password:segredo',
        'signOut',
      ]);
    });

    testWidgets('sign out com erro após exclusão não prende o usuário', (
      tester,
    ) async {
      final auth = FakeAuthService(
        user: FakeUser(),
        signOutError: Exception('sessão morta'),
      );
      await open(tester, auth);
      await tester.enterText(find.byType(TextField).first, 'EXCLUIR');
      await tester.enterText(find.byType(TextField).last, 'segredo');
      await tester.pump();
      await tester.tap(confirmButton());
      await tick(tester);
      expect(invoked, ['deleteAccount']);
      expect(find.text('Não foi possível sair da conta.'), findsNothing);
    });

    testWidgets('erro da callable mostra retry sem nova reautenticação', (
      tester,
    ) async {
      final auth = FakeAuthService(user: FakeUser());
      failWith = FirebaseException(
        plugin: 'cloud_functions',
        code: 'delete-incomplete',
      );
      await open(tester, auth);
      await tester.enterText(find.byType(TextField).first, 'EXCLUIR');
      await tester.enterText(find.byType(TextField).last, 'segredo');
      await tester.pump();
      await tester.tap(confirmButton());
      await tick(tester);
      expect(find.textContaining('A exclusão não terminou'), findsOneWidget);
      expect(auth.calls, ['reauth:password:segredo']);

      failWith = null;
      await tester.tap(find.widgetWithText(TextButton, 'Tentar novamente'));
      await tick(tester);
      expect(invoked, ['deleteAccount', 'deleteAccount']);
      expect(auth.calls, ['reauth:password:segredo', 'signOut']);
    });
  });
}
