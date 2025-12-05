import 'package:flutter/material.dart';
import '../../services/credentials_service.dart';

class LibraryLoginForm extends StatefulWidget {
  final TextEditingController useridController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;
  final bool isLoading;
  final bool isLoggedIn;
  final String loginMessage;
  final String errorMessage;

  const LibraryLoginForm({
    super.key,
    required this.useridController,
    required this.passwordController,
    required this.onLogin,
    required this.isLoading,
    required this.isLoggedIn,
    required this.loginMessage,
    required this.errorMessage,
  });

  @override
  State<LibraryLoginForm> createState() => _LibraryLoginFormState();
}

class _LibraryLoginFormState extends State<LibraryLoginForm> {
  bool _obscurePassword = true;
  bool _saveCredentials = false;
  bool _isLoadingCredentials = true;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final hasSaved = await CredentialsService.hasCredentialsSaved();
    final credentials = await CredentialsService.getCredentials();

    if (mounted) {
      setState(() {
        _saveCredentials = hasSaved;
        _isLoadingCredentials = false;
      });

      if (credentials != null) {
        widget.useridController.text = credentials['userId']!;
        widget.passwordController.text = credentials['password']!;
      }
    }
  }

  Future<void> _handleLogin() async {
    if (_saveCredentials) {
      await CredentialsService.saveCredentials(
        userId: widget.useridController.text.trim(),
        password: widget.passwordController.text.trim(),
      );
    } else {
      await CredentialsService.clearCredentials();
    }
    widget.onLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.loginMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isLoggedIn
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  widget.isLoggedIn ? Icons.check_circle : Icons.error,
                  color: widget.isLoggedIn
                      ? Colors.green.shade900
                      : Colors.red.shade900,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.loginMessage,
                    style: TextStyle(
                      color: widget.isLoggedIn
                          ? Colors.green.shade900
                          : Colors.red.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (widget.errorMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange.shade900),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.errorMessage,
                    style: TextStyle(color: Colors.orange.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: widget.useridController,
          decoration: const InputDecoration(
            labelText: 'Login (User ID)',
            hintText: 'Enter your student ID',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
          onSubmitted: (_) => _handleLogin(),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 12),
        if (!_isLoadingCredentials)
          CheckboxListTile(
            value: _saveCredentials,
            onChanged: (value) {
              setState(() {
                _saveCredentials = value ?? false;
              });
            },
            title: const Text(
              'Save credentials on this device',
              style: TextStyle(fontSize: 14),
            ),
            subtitle: const Text(
              'Your login will be remembered for next time',
              style: TextStyle(fontSize: 12),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: Colors.blue,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: widget.isLoading ? null : _handleLogin,
          icon: const Icon(Icons.login),
          label: Text(widget.isLoading ? 'Logging in...' : 'Login'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
