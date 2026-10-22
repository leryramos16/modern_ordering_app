import 'dart:io';

import 'package:backend/repositories/category_repository.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final categories = await context.read<CategoryRepository>().findAll();
  return Response.json(body: categories.map((c) => c.toJson()).toList());
}
