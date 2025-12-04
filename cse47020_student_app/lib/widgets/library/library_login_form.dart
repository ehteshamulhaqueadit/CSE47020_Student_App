import 'package:flutter/material.dart';

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
            hintText: 'Enter your student/staff ID',
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
          onSubmitted: (_) => widget.onLogin(),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: widget.isLoading ? null : widget.onLogin,
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
