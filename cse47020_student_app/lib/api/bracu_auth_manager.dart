import 'dart:developer';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BracuAuthManager {
  static final BracuAuthManager _instance = BracuAuthManager._internal();
  factory BracuAuthManager() => _instance;
  BracuAuthManager._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Call this to navigate to the login page
  Future<void> login(BuildContext context) async {
    Navigator.pushNamed(context, '/login');
  }

  // Stub: Implement later
  Future<void> logout() async {}

  // Stub: Implement later
  Future<void> refreshToken() async {}

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null && token.isNotEmpty;
  }

  // Stub: Implement later
  String? getToken() {
    return null;
  }

  Future<DateTime> getExpiryTime() async {
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
        log("Invalid access token");
        return DateTime.fromMillisecondsSinceEpoch(0);
      }

      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      final exp = payload['exp'];
      if (exp == null) {
        log("expiry field not found");
        return DateTime.fromMillisecondsSinceEpoch(0);
      }

      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (e) {
      log("Error Occured While decoding access token");
      return DateTime.fromMillisecondsSinceEpoch(0); // fallback on error
    }
  }

  Future<bool> isTokenExpired() async {
    final expiryTime = await getExpiryTime();
    return DateTime.now().isAfter(expiryTime);
  }
}
