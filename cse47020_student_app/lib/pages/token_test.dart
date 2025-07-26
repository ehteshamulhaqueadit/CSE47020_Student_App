import 'package:flutter/material.dart';
import 'package:cse47020_student_app/api/bracu_auth_manager.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenTest extends StatefulWidget {
  const TokenTest({super.key});

  @override
  State<TokenTest> createState() => _TokenTestState();
}

class _TokenTestState extends State<TokenTest> {
  final _storage = const FlutterSecureStorage();
  String _status = 'Welcome to Home Page';
  String _accessToken = '';
  String _refreshToken = '';

  void _handleRefreshToken() {
    setState(() {
      _status = 'Refreshing token...';
    });

    BracuAuthManager()
        .refreshToken()
        .then((_) async {
          final access =
              await _storage.read(key: 'access_token') ?? 'No access_token';
          final refresh =
              await _storage.read(key: 'refresh_token') ?? 'No refresh_token';

          setState(() {
            _status = 'Token refresh successful!';
            _accessToken = access;
            _refreshToken = refresh;
          });
        })
        .catchError((e) {
          setState(() {
            _status = 'Failed to refresh token: $e';
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _status,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _handleRefreshToken,
                child: const Text("Refresh Token"),
              ),
              const SizedBox(height: 30),
              const Text(
                "Access Token:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(_accessToken),
              const SizedBox(height: 20),
              const Text(
                "Refresh Token:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(_refreshToken),
            ],
          ),
        ),
      ),
    );
  }
}
