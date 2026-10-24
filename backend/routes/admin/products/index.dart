import 'dart:io';

import 'package:backend/repositories/category_repository.dart';
import 'package:backend/repositories/product_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final name = (body['name'] as String? ?? '').trim();
  final description = (body['description'] as String? ?? '').trim();
  final priceText = body['price']?.toString();
  final categoryId = body['categoryId'] as int?;
  final imageUrl = (body['imageUrl'] as String? ?? '').trim();

  final error =
      Validators.productName(name) ??
      Validators.price(priceText) ??
      (categoryId == null ? 'Choose a category' : null) ??
      _imageUrlError(imageUrl);

  if (error != null) return _badRequest(error);

  if (!await context.read<CategoryRepository>().exists(categoryId!)) {
    return _badRequest('Category not found');
  }

  final product = await context.read<ProductRepository>().create(
    categoryId: categoryId,
    name: name,
    price: double.parse(priceText!),
    description: description.isEmpty ? null : description,
    imageUrl: imageUrl.isEmpty ? null : imageUrl,
  );

  return Response.json(statusCode: HttpStatus.created, body: product.toJson());
}

Response _badRequest(String error) => Response.json(
  statusCode: HttpStatus.badRequest,
  body: {'error': error},
);

String? _imageUrlError(String url) {
  if (url.isEmpty) return null;
  if (!url.startsWith('/uploads/') || url.contains('..') || url.length > 255) {
    return 'Invalid image';
  }
  return null;
}
