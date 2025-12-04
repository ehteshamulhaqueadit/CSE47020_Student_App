import 'package:flutter/material.dart';

class LibraryLoginForm extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Icon(Icons.local_library, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Library Login',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        if (loginMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isLoggedIn ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isLoggedIn ? Icons.check_circle : Icons.error,
                  color: isLoggedIn
                      ? Colors.green.shade900
                      : Colors.red.shade900,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loginMessage,
                    style: TextStyle(
                      color: isLoggedIn
                          ? Colors.green.shade900
                          : Colors.red.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (errorMessage.isNotEmpty) ...[
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
                    errorMessage,
                    style: TextStyle(color: Colors.orange.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: useridController,
          decoration: const InputDecoration(
            labelText: 'Login (User ID)',
            hintText: 'Enter your student/staff ID',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            hintText: 'Enter your password',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
          onSubmitted: (_) => onLogin(),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: isLoading ? null : onLogin,
          icon: const Icon(Icons.login),
          label: Text(isLoading ? 'Logging in...' : 'Login'),
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
