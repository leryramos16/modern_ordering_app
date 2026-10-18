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
  final name = (body['name'] as String? ?? '').trim();
  final email = (body['email'] as String? ?? '').trim().toLowerCase();
  final password = body['password'] as String? ?? '';

  if (name.isEmpty || !email.contains('@') || password.length < 8) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Name, valid email and password (8+ chars) required'},
    );
  }

  final users = context.read<UserRepository>();
  if (await users.findByEmail(email) != null) {
    return Response.json(
      statusCode: HttpStatus.conflict,
      body: {'error': 'Email is already registered'},
    );
  }

  final user = await users.create(
    name: name,
    email: email,
    passwordHash: BCrypt.hashpw(password, BCrypt.gensalt()),
  );
  final token = context.read<JwtService>().createToken(user.id);

  return Response.json(
    statusCode: HttpStatus.created,
    body: {'token': token, 'user': user.toJson()},
  );
}
