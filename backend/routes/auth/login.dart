import 'dart:io';

import 'package:backend/auth/jwt_service.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final email = (body['email'] as String? ?? '').trim().toLowerCase();
  final password = body['password'] as String? ?? '';

  final record = await context.read<UserRepository>().findByEmail(email);
  if (record == null || !BCrypt.checkpw(password, record.passwordHash)) {
    return Response.json(
      statusCode: HttpStatus.unauthorized,
      body: {'error': 'Invalid email or password'},
    );
  }

  final token = context.read<JwtService>().createToken(record.user.id);
  return Response.json(body: {'token': token, 'user': record.user.toJson()});
}
