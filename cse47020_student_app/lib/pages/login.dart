import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _accessTokenController = TextEditingController();
  final _refreshTokenController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  String _status = '';

  Future<void> _saveTokens() async {
    final accessToken = _accessTokenController.text.trim();
    final refreshToken = _refreshTokenController.text.trim();

    if (accessToken.isEmpty) {
      setState(() => _status = "Access token is required.");
      return;
    }

    await _storage.write(key: 'access_token', value: accessToken);
    if (refreshToken.isNotEmpty) {
      await _storage.write(key: 'refresh_token', value: refreshToken);
    }

    setState(() => _status = "Token(s) saved!");
  }

  void _handleSave() {
    _saveTokens().then((_) {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Enter Tokens")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Access Token (required):",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _accessTokenController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Paste your access token...',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Refresh Token (optional):",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _refreshTokenController,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Paste your refresh token...',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _handleSave, child: const Text("Save")),
            const SizedBox(height: 10),
            Text(_status, style: const TextStyle(color: Colors.green)),
          ],
        ),
      ),
    );
  }
}
