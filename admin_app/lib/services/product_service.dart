import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_models/shared_models.dart';

import '../config.dart';
import 'auth_service.dart';
import 'dart:typed_data';

class ApiException implements Exception {
  ApiException(this.message);
  final String message;
}

/// Products + categories, loaded together.
typedef MenuData = ({List<Product> products, List<ProductCategory> categories});

class ProductService {
  Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/products'));
    if (response.statusCode != 200) throw _error(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Both requests at the same time; used by Overview and Products.
  Future<MenuData> fetchMenu() async {
    final (products, categories) = await (
      fetchProducts(),
      fetchCategories(),
    ).wait;
    return (products: products, categories: categories);
  }

  Future<List<ProductCategory>> fetchCategories() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/categories'));
    if (response.statusCode != 200) throw _error(response);
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ProductCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductCategory> createCategory(String name) async {
    final token = await authService.token();
    final response = await http.post(
      Uri.parse('$apiBaseUrl/admin/categories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'name': name}),
    );
    if (response.statusCode != 201) throw _error(response);
    return ProductCategory.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Product> createProduct({
    required String name,
    required double price,
    required int categoryId,
    String? description,
    String? imageUrl,
  }) async {
    final token = await authService.token();
    final response = await http.post(
      Uri.parse('$apiBaseUrl/admin/products'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', //proves I'm the admin
      },
      body: jsonEncode({
        'name': name,
        'price': price,
        'categoryId': categoryId,
        'description': description,
        'imageUrl': imageUrl,
      }),
    );
    if (response.statusCode != 201) throw _error(response);
    return Product.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Sends the photo; returns where the server saved it, e.g. "/uploads/abc.jpg".
  Future<String> uploadImage(Uint8List bytes, String fileName) async {
    final token = await authService.token();
    final request =
        http.MultipartRequest('POST', Uri.parse('$apiBaseUrl/admin/uploads'))
          ..headers['Authorization'] = 'Bearer $token'
          ..files.add(
            http.MultipartFile.fromBytes('image', bytes, filename: fileName),
          );

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode != 201) throw _error(response);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['url'] as String;
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

final productService = ProductService();
