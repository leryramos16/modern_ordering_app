import 'dart:io';

import 'package:backend/repositories/order_repository.dart';
import 'package:dart_frog/dart_frog.dart';
import 'package:shared_models/shared_models.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final orderId = int.tryParse(id);
  if (orderId == null) return _error(HttpStatus.badRequest, 'Invalid order id');

  if (context.request.method != HttpMethod.patch) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final body = await context.request.json() as Map<String, dynamic>;
  final status = body['status'] as String?;

  final orders = context.read<OrderRepository>();
  final order = await orders.findById(orderId);
  if (order == null) return _error(HttpStatus.notFound, 'Order not found');

  // Only one step forward (or cancel, while still allowed).
  if (status == null || !OrderStatus.nextOf(order.status).contains(status)) {
    return _error(
      HttpStatus.badRequest,
      'A ${OrderStatus.label(order.status).toLowerCase()} order '
      "can't be changed to ${status ?? 'that'}",
    );
  }

  final changed = await orders.updateStatus(
    orderId,
    from: order.status,
    to: status,
  );
  if (!changed) {
    return _error(
      HttpStatus.conflict,
      'This order was just updated by someone else. Refresh and try again.',
    );
  }

  final updated = await orders.findById(orderId);
  return Response.json(body: updated!.toJson());
}

Response _error(int status, String message) =>
    Response.json(statusCode: status, body: {'error': message});
