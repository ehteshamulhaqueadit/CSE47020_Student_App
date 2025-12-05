import 'package:shared_preferences/shared_preferences.dart';

class CredentialsService {
  static const String _keyUserId = 'library_user_id';
  static const String _keyPassword = 'library_password';
  static const String _keySaveCredentials = 'save_credentials';

  /// Save user credentials to device storage
  static Future<void> saveCredentials({
    required String userId,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyPassword, password);
    await prefs.setBool(_keySaveCredentials, true);
  }

  /// Retrieve saved credentials from device storage
  static Future<Map<String, String>?> getCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final saveCredentials = prefs.getBool(_keySaveCredentials) ?? false;

    if (!saveCredentials) return null;

    final userId = prefs.getString(_keyUserId);
    final password = prefs.getString(_keyPassword);

    if (userId != null && password != null) {
      return {'userId': userId, 'password': password};
    }

    return null;
  }

  /// Clear saved credentials from device storage
  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyPassword);
    await prefs.setBool(_keySaveCredentials, false);
  }

  /// Check if credentials are currently saved
  static Future<bool> hasCredentialsSaved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySaveCredentials) ?? false;
  }
}
