import 'dart:io';

import 'package:backend/auth/jwt_service.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';

Middleware requireUser() {
  return (handler) {
    return (context) async {
      final header = context.request.headers['Authorization'] ?? '';
      if (!header.startsWith('Bearer ')) return _unauthorized();

      final userId = context.read<JwtService>().verifyToken(
        header.substring(7),
      );
      if (userId == null) return _unauthorized();

      final user = await context.read<UserRepository>().findById(userId);
      if (user == null) return _unauthorized();

      // Makes the logged-in user available to every route below
      return handler(context.provide<User>(() => user));
    };
  };
}

Response _unauthorized() => Response.json(
  statusCode: HttpStatus.unauthorized,
  body: {'error': 'Not logged in'},
);
