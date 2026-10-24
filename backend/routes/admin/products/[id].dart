import 'dart:io';

import 'package:backend/product_input.dart';
import 'package:backend/repositories/category_repository.dart';
import 'package:backend/repositories/product_repository.dart';
import 'package:backend/uploads.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final productId = int.tryParse(id); // "/admin/products/abc" → null
  if (productId == null)
    return _error(HttpStatus.badRequest, 'Invalid product id');

  return switch (context.request.method) {
    HttpMethod.put => _update(context, productId),
    HttpMethod.delete => _delete(context, productId),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _update(RequestContext context, int id) async {
  final products = context.read<ProductRepository>();
  final existing = await products.findById(id);
  if (existing == null) return _error(HttpStatus.notFound, 'Product not found');

  final body = await context.request.json() as Map<String, dynamic>;
  final (input, error) = readProductInput(body);
  if (input == null) return _error(HttpStatus.badRequest, error!);

  if (!await context.read<CategoryRepository>().exists(input.categoryId)) {
    return _error(HttpStatus.badRequest, 'Category not found');
  }

  final product = await products.update(id, input);
  if (product == null) return _error(HttpStatus.notFound, 'Product not found');

  // Photo replaced or removed? Delete the old file so it doesn't pile up.
  if (existing.imageUrl != product.imageUrl) {
    await deleteUpload(existing.imageUrl);
  }
  return Response.json(body: product.toJson());
}

Future<Response> _delete(RequestContext context, int id) async {
  final products = context.read<ProductRepository>();
  final existing = await products.findById(id);
  if (existing == null) return _error(HttpStatus.notFound, 'Product not found');

  if (await products.isOrdered(id)) {
    return _error(
      HttpStatus.conflict,
      '"${existing.name}" is in past orders, so it can\'t be deleted. '
      'Turn off "Show on menu" to hide it instead.',
    );
  }

  await products.delete(id);
  await deleteUpload(existing.imageUrl); // its photo goes too
  return Response(statusCode: HttpStatus.noContent);
}

Response _error(int status, String message) =>
    Response.json(statusCode: status, body: {'error': message});
