import 'dart:io';

import 'package:backend/auth/jwt_service.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final header = context.request.headers['Authorization'] ?? '';
  if (!header.startsWith('Bearer ')) {
    return _unauthorized();
  }

  final userId = context.read<JwtService>().verifyToken(header.substring(7));
  if (userId == null) return _unauthorized();

  final user = await context.read<UserRepository>().findById(userId);
  if (user == null) return _unauthorized();

  return Response.json(body: user.toJson());
}

Response _unauthorized() => Response.json(
  statusCode: HttpStatus.unauthorized,
  body: {'error': 'Not logged in'},
);
