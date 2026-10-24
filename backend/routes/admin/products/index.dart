import 'dart:io';

import 'package:backend/product_input.dart';
import 'package:backend/repositories/category_repository.dart';
import 'package:backend/repositories/product_repository.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _list(context),
    HttpMethod.post => _create(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

/// Admin list: includes hidden products (the customers' GET /products doesn't).
Future<Response> _list(RequestContext context) async {
  final products = await context.read<ProductRepository>().findAllForAdmin();
  return Response.json(body: products.map((p) => p.toJson()).toList());
}

Future<Response> _create(RequestContext context) async {
  final body = await context.request.json() as Map<String, dynamic>;
  final (input, error) = readProductInput(body);
  if (input == null) return _badRequest(error!);

  if (!await context.read<CategoryRepository>().exists(input.categoryId)) {
    return _badRequest('Category not found');
  }

  final product = await context.read<ProductRepository>().create(
    categoryId: input.categoryId,
    name: input.name,
    price: input.price,
    description: input.description,
    imageUrl: input.imageUrl,
  );
  return Response.json(statusCode: HttpStatus.created, body: product.toJson());
}

Response _badRequest(String error) => Response.json(
  statusCode: HttpStatus.badRequest,
  body: {'error': error},
);
