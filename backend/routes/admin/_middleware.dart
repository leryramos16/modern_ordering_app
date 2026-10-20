import 'dart:io';

import 'package:backend/auth/auth_middleware.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';

Handler middleware(Handler handler) {
  return handler
      .use(_requireAdmin())
      .use(requireUser()); // the LAST .use() runs FIRST
}

Middleware _requireAdmin() =>
    (handler) => (context) {
      if (context.read<User>().role != Roles.admin) {
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {'error': 'Admins only'},
        );
      }
      return handler(context);
    };
