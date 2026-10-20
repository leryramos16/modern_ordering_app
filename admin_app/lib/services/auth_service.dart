import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_models/shared_models.dart';

import '../config.dart';

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
}

class AuthService {
  static const _tokenKey = 'auth_token';
  final _storage = const FlutterSecureStorage();

  Future<User> login(String email, String password) async {
    final user = await _authenticate('/auth/login', {
      'email': email,
      'password': password,
    });
    if (user.role != Roles.admin) {
      await logout();
      throw AuthException('This account is not an admin');
    }
    return user;
  }

  Future<User> _authenticate(String path, Map<String, String> body) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw AuthException(data['error'] as String? ?? 'Something went wrong');
    }

    await _storage.write(key: _tokenKey, value: data['token'] as String);
    return User.fromJson(data['user'] as Map<String, dynamic>);
  }

  /// Called on app start: returns the user if a saved token is still valid.
  Future<User?> currentUser() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return null;

    final response = await http.get(
      Uri.parse('$apiBaseUrl/auth/me'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      await logout();
      return null;
    }
    return User.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<void> logout() => _storage.delete(key: _tokenKey);
}

// One shared instance for the whole app (simple for now; later you can
// swap this for a state-management package like provider or riverpod).
final authService = AuthService();
