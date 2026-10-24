import 'dart:io';

import 'package:backend/repositories/category_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:postgres/postgres.dart';
import 'package:shared_models/shared_models.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final categoryId = int.tryParse(id);
  if (categoryId == null)
    return _error(HttpStatus.badRequest, 'Invalid category id');

  return switch (context.request.method) {
    HttpMethod.put => _rename(context, categoryId),
    HttpMethod.delete => _delete(context, categoryId),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _rename(RequestContext context, int id) async {
  final body = await context.request.json() as Map<String, dynamic>;
  final name = (body['name'] as String? ?? '').trim();

  final error = Validators.categoryName(name);
  if (error != null) return _error(HttpStatus.badRequest, error);

  try {
    final category = await context.read<CategoryRepository>().update(id, name);
    if (category == null)
      return _error(HttpStatus.notFound, 'Category not found');
    return Response.json(body: category.toJson());
  } on ServerException catch (e) {
    if (e.code == '23505') {
      // our unique index: another category already has this name
      return _error(HttpStatus.conflict, '"$name" already exists');
    }
    rethrow;
  }
}

Future<Response> _delete(RequestContext context, int id) async {
  final categories = context.read<CategoryRepository>();

  final count = await categories.productCount(id);
  if (count > 0) {
    return _error(
      HttpStatus.conflict,
      'This category still has $count product${count == 1 ? '' : 's'}. '
      'Move them to another category first.',
    );
  }

  try {
    final deleted = await categories.delete(id);
    if (!deleted) return _error(HttpStatus.notFound, 'Category not found');
    return Response(statusCode: HttpStatus.noContent);
  } on ServerException catch (e) {
    // 23503 = foreign key: a product was added to it a split second ago
    if (e.code == '23503') {
      return _error(HttpStatus.conflict, 'This category still has products.');
    }
    rethrow;
  }
}

Response _error(int status, String message) =>
    Response.json(statusCode: status, body: {'error': message});
