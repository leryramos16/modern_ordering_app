import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_models/shared_models.dart';

import '../config.dart';

class ProductService {
  Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/products'));
    if (response.statusCode != 200) {
      throw Exception('Could not load products (${response.statusCode})');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductCategory>> fetchCategories() async {
    final response = await http.get(Uri.parse('$apiBaseUrl/categories'));
    if (response.statusCode != 200) {
      throw Exception('Could not load categories (${response.statusCode})');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => ProductCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final productService = ProductService();
