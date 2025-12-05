import 'package:flutter/material.dart';
import 'pages/home.dart';
import 'pages/login.dart';
import 'api/bracu_auth_manager.dart';
import 'services/notification_service.dart';

void main() async {
  // required to safely call async code before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService().initialize();

  // Check login status before runApp
  final bool loggedIn = await BracuAuthManager().isLoggedIn();
  // Every widget rebuild will be in console
  // https://dev.to/alaminkarno/why-your-flutter-app-rebuilds-too-much-and-how-to-fix-it-bpi
  // debugPrintRebuildDirtyWidgets = true;
  runApp(
    MaterialApp(
      initialRoute: loggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
      },
    ),
  );
}
