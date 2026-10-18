import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class JwtService {
  JwtService()
    : _key = SecretKey(
        Platform.environment['JWT_SECRET'] ?? 'dev-only-change-me',
      );

  final SecretKey _key;

  String createToken(int userId) {
    final jwt = JWT({}, subject: '$userId');
    return jwt.sign(_key, expiresIn: const Duration(days: 7));
  }

  /// Returns the user id if the token is valid, otherwise null.
  int? verifyToken(String token) {
    try {
      final jwt = JWT.verify(token, _key);
      return int.tryParse(jwt.subject ?? '');
    } on JWTException {
      return null;
    }
  }
}
