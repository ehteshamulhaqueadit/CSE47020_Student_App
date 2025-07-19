import 'package:flutter/material.dart';
import 'pages/home.dart';
import 'pages/login.dart';
import 'api/bracu_auth_manager.dart';

void main() async {
  // required to safely call async code before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Check login status before runApp
  final bool loggedIn = await BracuAuthManager().isLoggedIn();

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
