import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/locale_controller.dart';
import 'services/theme_controller.dart';
import 'theme/qio_theme.dart';
import 'widgets/qio_loading_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (const bool.fromEnvironment('USE_EMULATORS')) {
    const host = String.fromEnvironment(
      'EMULATOR_HOST',
      defaultValue: 'localhost',
    );
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    FirebaseDatabase.instance.useDatabaseEmulator(host, 9000);
  }
  await ThemeController.instance.load();
  await LocaleController.instance.load();
  runApp(const QioApp());
}

class QioApp extends StatefulWidget {
  const QioApp({super.key});

  @override
  State<QioApp> createState() => _QioAppState();
}

class _QioAppState extends State<QioApp> with WidgetsBindingObserver {
  final _theme = ThemeController.instance;
  final _locale = LocaleController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _theme.addListener(_onThemeChanged);
    _locale.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _theme.removeListener(_onThemeChanged);
    _locale.removeListener(_onThemeChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() => _onThemeChanged();

  void _onThemeChanged() {
    setState(() {});
    void markDirty(Element e) {
      e.markNeedsBuild();
      e.visitChildren(markDirty);
    }

    WidgetsBinding.instance.rootElement?.visitChildren(markDirty);
  }

  @override
  Widget build(BuildContext context) {
    final brightness = _theme.resolve(
      WidgetsBinding.instance.platformDispatcher.platformBrightness,
    );
    return MaterialApp(
      title: 'Qio',
      locale: _locale.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supported) {
        for (final s in supported) {
          if (s.languageCode == locale?.languageCode) return s;
        }
        return const Locale('pt');
      },
      debugShowCheckedModeBanner: false,
      theme: QioTheme.forBrightness(brightness),
      home: StreamBuilder(
        stream: AuthService.instance.authStateChanges,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const QioLoadingView();
          }
          if (snap.hasData) return const HomeScreen();
          return const LoginScreen();
        },
      ),
    );
  }
}
