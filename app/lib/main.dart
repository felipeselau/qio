import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/haptics.dart';
import 'services/locale_controller.dart';
import 'services/queue_service.dart';
import 'services/theme_controller.dart';
import 'theme/qio_theme.dart';
import 'widgets/connection_banner.dart';
import 'widgets/qio_loading_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (!kIsWeb) {
    final reportCrashes =
        !kDebugMode && !const bool.fromEnvironment('USE_EMULATORS');
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      reportCrashes,
    );
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
  if (const bool.fromEnvironment('USE_EMULATORS')) {
    const host = String.fromEnvironment(
      'EMULATOR_HOST',
      defaultValue: 'localhost',
    );
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    FirebaseDatabase.instance.useDatabaseEmulator(host, 9000);
  }
  if (!kIsWeb) await AnalyticsController.instance.load();
  await ThemeController.instance.load();
  await Haptics.instance.load();
  await LocaleController.instance.load();
  runApp(const QioApp());
}

class QioApp extends StatefulWidget {
  const QioApp({super.key});

  @override
  State<QioApp> createState() => _QioAppState();
}

class _QioAppState extends State<QioApp> {
  final _theme = ThemeController.instance;
  late final Stream<bool> _connection = QueueService.instance
      .watchConnection()
      .asBroadcastStream();
  final _locale = LocaleController.instance;

  @override
  void initState() {
    super.initState();
    _theme.addListener(_onThemeChanged);
    _locale.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _theme.removeListener(_onThemeChanged);
    _locale.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
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
      builder: (context, child) => ConnectionBanner(
        connected: _connection,
        child: child ?? const SizedBox.shrink(),
      ),
      theme: QioTheme.light,
      darkTheme: QioTheme.dark,
      themeMode: _theme.mode,
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
