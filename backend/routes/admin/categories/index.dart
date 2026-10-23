import 'dart:io';

import 'package:backend/repositories/category_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:shared_models/shared_models.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final name = (body['name'] as String? ?? '').trim();

  final error = Validators.categoryName(name);
  if (error != null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': error},
    );
  }

  try {
    final category = await context.read<CategoryRepository>().create(name);
    return Response.json(
      statusCode: HttpStatus.created,
      body: category.toJson(),
    );
  } on ServerException catch (e) {
    // 23505 = PostgreSQL's code for "unique rule broken" (our index from Step 1)
    if (e.code == '23505') {
      return Response.json(
        statusCode: HttpStatus.conflict,
        body: {'error': '"$name" already exists'},
      );
    }
    rethrow; // any other database problem is a real bug, so let it show
  }
}
