import 'package:flutter/material.dart';
import 'package:cse47020_student_app/api/bracu_auth_manager.dart'; // Replace `your_project` with your actual package name

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String expiryText = 'Checking token...';

  @override
  void initState() {
    super.initState();
    checkTokenStatus();
  }

  Future<void> checkTokenStatus() async {
    final authManager = BracuAuthManager();
    final tokenInfo = await authManager.getExpiryTime();

    setState(() {
      if (tokenInfo == null) {
        expiryText = 'Token not found or invalid.';
      } else {
        expiryText = 'Token expires at: ${tokenInfo.toLocal()}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(child: Text(expiryText)),
    );
  }
}
