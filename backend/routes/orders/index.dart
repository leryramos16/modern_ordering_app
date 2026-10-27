import 'dart:io';

import 'package:backend/repositories/order_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';

const _maxQuantity = 20; // per product
const _maxLines = 50; // different products per order

Future<Response> onRequest(RequestContext context) async {
  return switch (context.request.method) {
    HttpMethod.get => _list(context),
    HttpMethod.post => _create(context),
    _ => Future.value(Response(statusCode: HttpStatus.methodNotAllowed)),
  };
}

/// The logged-in customer's OWN orders. Never anyone else's.
Future<Response> _list(RequestContext context) async {
  final user = context.read<User>();
  final orders = await context.read<OrderRepository>().findForUser(user.id);
  return Response.json(body: orders.map((o) => o.toJson()).toList());
}

Future<Response> _create(RequestContext context) async {
  final body = await context.request.json() as Map<String, dynamic>;
  final address = (body['deliveryAddress'] as String? ?? '').trim();
  final phone = (body['contactPhone'] as String? ?? '').trim();
  final notes = (body['notes'] as String? ?? '').trim();

  final error =
      Validators.address(address) ??
      Validators.phone(phone) ??
      Validators.notes(notes);
  if (error != null) return _error(HttpStatus.badRequest, error);

  // Build {productId: quantity}. If the same product appears twice, add them up.
  final quantities = <int, int>{};
  for (final item in body['items'] as List<dynamic>? ?? const []) {
    if (item is! Map<String, dynamic>) {
      return _error(HttpStatus.badRequest, 'Invalid cart item');
    }
    final productId = item['productId'] as int?;
    final quantity = item['quantity'] as int?;
    if (productId == null || quantity == null || quantity < 1) {
      return _error(HttpStatus.badRequest, 'Invalid cart item');
    }
    quantities[productId] = (quantities[productId] ?? 0) + quantity;
  }
  if (quantities.isEmpty) {
    return _error(HttpStatus.badRequest, 'Your cart is empty');
  }
  if (quantities.length > _maxLines) {
    return _error(
      HttpStatus.badRequest,
      'Too many different items in one order',
    );
  }
  if (quantities.values.any((q) => q > _maxQuantity)) {
    return _error(
      HttpStatus.badRequest,
      'You can order up to $_maxQuantity of each item',
    );
  }

  // WHO is ordering comes from the login token, never from the request body.
  final user = context.read<User>();

  try {
    final order = await context.read<OrderRepository>().create(
      userId: user.id,
      quantities: quantities,
      deliveryAddress: address,
      contactPhone: phone,
      notes: notes.isEmpty ? null : notes,
    );
    return Response.json(statusCode: HttpStatus.created, body: order.toJson());
  } on OrderException catch (e) {
    return _error(HttpStatus.conflict, e.message);
  }
}

Response _error(int status, String message) =>
    Response.json(statusCode: status, body: {'error': message});
