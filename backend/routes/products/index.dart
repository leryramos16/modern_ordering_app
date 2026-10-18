import 'dart:io';
import 'package:backend/repositories/product_repository.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _getAll(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

Future<Response> _getAll(RequestContext context) async {
  final products = await context.read<ProductRepository>().findAll();
  return Response.json(
    body: products.map((p) => p.toJson()).toList(),
  );
}
