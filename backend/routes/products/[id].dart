import 'dart:io';
import 'package:backend/repositories/product_repository.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final productId = int.tryParse(id);
  if (productId == null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'Invalid product id'},
    );
  }

  final product = await context.read<ProductRepository>().findById(productId);
  if (product == null) {
    return Response.json(
      statusCode: HttpStatus.notFound,
      body: {'error': 'Product not found'},
    );
  }

  return Response.json(body: product.toJson());
}
