import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _tokenController = TextEditingController();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  String _status = '';

  Future<void> _saveToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() => _status = "Token is empty!");
      return;
    }

    await _storage.write(key: 'access_token', value: token);
    setState(() => _status = "Access token saved!");

    // Navigate to home.dart
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Access Token")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Paste your access_token below:",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tokenController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'eyJhbGciOiJIUzI1NiIsInR5...',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveToken,
              child: const Text("Save Token"),
            ),
            const SizedBox(height: 10),
            Text(_status, style: const TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}

