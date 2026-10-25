import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_models/shared_models.dart';

import '../config.dart';
import 'auth_service.dart';
import 'cart.dart';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
}

class OrderService {
  Future<Order> placeOrder({
    required List<CartLine> lines,
    required String deliveryAddress,
    required String contactPhone,
    String? notes,
  }) async {
    final token = await authService.token();
    final response = await http.post(
      Uri.parse('$apiBaseUrl/orders'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        // Only WHAT and HOW MANY. Never prices: the server decides those.
        'items': [
          for (final line in lines)
            {'productId': line.product.id, 'quantity': line.quantity},
        ],
        'deliveryAddress': deliveryAddress,
        'contactPhone': contactPhone,
        'notes': notes,
      }),
    );
    if (response.statusCode != 201) throw _error(response);
    return Order.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Reads {"error": "..."} if the server sent JSON; never crashes on plain text.
  ApiException _error(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return ApiException(data['error'] as String? ?? 'Something went wrong');
    } catch (_) {
      return ApiException('Server error (${response.statusCode})');
    }
  }
}

final orderService = OrderService();
