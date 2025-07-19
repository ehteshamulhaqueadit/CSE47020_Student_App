import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:cse47020_student_app/tools/prints.dart';

class BracuAuthManager {
  static final BracuAuthManager _instance = BracuAuthManager._internal();
  factory BracuAuthManager() => _instance;
  BracuAuthManager._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Call this to navigate to the login page
  Future<void> login(BuildContext context) async {
    Navigator.pushNamed(context, '/login');
  }

  Future<void> logout(BuildContext context) async {
    const endSessionEndpoint =
        'https://sso.bracu.ac.bd/realms/bracu/protocol/openid-connect/logout';

    try {
      final refreshToken = await _storage.read(key: 'refresh_token');

      // Call SSO logout endpoint
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final response = await http.post(
          Uri.parse(endSessionEndpoint),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'client_id': 'slm', 'refresh_token': refreshToken},
        );

        if (response.statusCode == 200) {
          prints('Logged out from SSO successfully.');
        } else {
          prints('Failed to logout from SSO. Status: ${response.statusCode}');
        }
      }

      // Clear secure storage
      await _storage.deleteAll();

      // Clear shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      prints('Local storage cleared.');

      // Navigate to login screen and remove all previous routes
      // Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } catch (e) {
      prints('Error during logout: $e');
    }
  }

  Future<bool> refreshToken() async {
    final tokenEndpoint =
        'https://sso.bracu.ac.bd/realms/bracu/protocol/openid-connect/token';
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) {
        prints('No refresh token found.');
        return false;
      }

      final response = await http.post(
        Uri.parse(tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': 'slm', // Replace with your client ID
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final newAccessToken = data['access_token'];
        final newRefreshToken = data['refresh_token'];

        await _storage.write(key: 'access_token', value: newAccessToken);
        await _storage.write(key: 'refresh_token', value: newRefreshToken);

        prints('Token refreshed successfully.');
        return true;
      } else if (response.statusCode == 400) {
        return false;
      } else {
        prints('Failed to refresh token. Status: ${response.statusCode}');
        prints(response.body);
        return false;
      }
    } catch (e) {
      prints('Error refreshing token: $e');
      return false;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null && token.isNotEmpty;
  }

  Future<DateTime> getTokenExpiryTime() async {
    final token = await _storage.read(key: 'access_token');

    if (token == null || token.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(
        0,
      ); // fallback: clearly expired
    }

    try {
      final parts = token.split('.');
      //JWTs always have a format -> HEADER.PAYLOAD.SIGNATURE
      // if it doesnt follow that means tis an invalid JWT
      if (parts.length != 3) {
        prints("Invalid access token");
        return DateTime.fromMillisecondsSinceEpoch(0);
      }

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload['exp'];
      if (exp == null) {
        prints("Expiry field not found");
        return DateTime.fromMillisecondsSinceEpoch(0);
      }

      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (e) {
      prints("Error Occured While decoding access token: $e");
      return DateTime.fromMillisecondsSinceEpoch(0); // fallback on error
    }
  }

  Future<bool> isTokenExpired() async {
    final expiryTime = await getTokenExpiryTime();
    return DateTime.now().isAfter(expiryTime);
  }
}
