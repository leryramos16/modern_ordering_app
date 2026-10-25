import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_models/shared_models.dart';

import '../config.dart';
import 'auth_service.dart';
import 'product_service.dart' show ApiException;

class OrderService {
  Future<List<Order>> fetchOrders() async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/admin/orders'),
      headers: await _authHeaders(),
    );
    if (response.statusCode != 200) throw _error(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Order> updateStatus(int id, String status) async {
    final response = await http.patch(
      Uri.parse('$apiBaseUrl/admin/orders/$id'),
      headers: await _authHeaders(),
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode != 200) throw _error(response);
    return Order.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Map<String, String>> _authHeaders() async => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${await authService.token()}',
  };

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
