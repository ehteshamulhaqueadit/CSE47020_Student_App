// test/check_token.dart

import 'package:flutter/widgets.dart';
import 'package:cse47020_student_app/api/bracu_auth_manager.dart'; // update with correct path

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final authManager = BracuAuthManager();
  final expired = await authManager.isTokenExpired();
  print('Access token expired: $expired');
}
