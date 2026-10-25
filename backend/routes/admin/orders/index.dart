import 'dart:io';

import 'package:backend/repositories/order_repository.dart';
import 'package:dart_frog/dart_frog.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }
  final orders = await context.read<OrderRepository>().findRecent();
  return Response.json(body: orders.map((o) => o.toJson()).toList());
}
