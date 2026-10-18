import 'dart:io';

import 'package:backend/auth/jwt_service.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final name = (body['name'] as String? ?? '').trim();
  final email = (body['email'] as String? ?? '').trim().toLowerCase();
  final password = body['password'] as String? ?? '';

  final error =
      Validators.name(name) ??
      Validators.email(email) ??
      Validators.password(password);
  if (error != null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': error},
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
