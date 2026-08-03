import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'theme/qio_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const QioApp());
}

class QioApp extends StatelessWidget {
  const QioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qio',
      debugShowCheckedModeBanner: false,
      theme: QioTheme.light,
      home: StreamBuilder(
        stream: AuthService.instance.authStateChanges,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snap.hasData) return const HomeScreen();
          return const LoginScreen();
        },
      ),
    );
  }
}
