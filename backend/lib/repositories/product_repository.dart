import 'package:postgres/postgres.dart';
import 'package:shared_models/shared_models.dart';

import 'package:backend/product_input.dart';

class ProductRepository {
  ProductRepository(this._db);

  final Pool _db;

  static const _columns =
      'id, category_id, name, description, price, image_url, is_available';

  Future<List<Product>> findAll() async {
    final result = await _db.execute(
      'SELECT $_columns FROM products '
      'WHERE is_available = true ORDER BY name',
    );
    return result.map((row) => _fromRow(row.toColumnMap())).toList();
  }

  Future<Product?> findById(int id) async {
    final result = await _db.execute(
      Sql.named('SELECT $_columns FROM products WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return _fromRow(result.first.toColumnMap());
  }

  /// Admin list: every product, including hidden ones.
  Future<List<Product>> findAllForAdmin() async {
    final result = await _db.execute(
      'SELECT $_columns FROM products ORDER BY name',
    );
    return result.map((row) => _fromRow(row.toColumnMap())).toList();
  }

  /// Returns null if no product has this id.
  Future<Product?> update(int id, ProductInput input) async {
    final result = await _db.execute(
      Sql.named(
        'UPDATE products SET category_id = @categoryId, name = @name, '
        'description = @description, price = @price, image_url = @imageUrl, '
        'is_available = @isAvailable '
        'WHERE id = @id RETURNING $_columns',
      ),
      parameters: {
        'id': id,
        'categoryId': input.categoryId,
        'name': input.name,
        'description': input.description,
        'price': input.price,
        'imageUrl': input.imageUrl,
        'isAvailable': input.isAvailable,
      },
    );
    if (result.isEmpty) return null;
    return _fromRow(result.first.toColumnMap());
  }

  /// Has any customer ever ordered this product?
  Future<bool> isOrdered(int id) async {
    final result = await _db.execute(
      Sql.named('SELECT 1 FROM order_items WHERE product_id = @id LIMIT 1'),
      parameters: {'id': id},
    );
    return result.isNotEmpty;
  }

  Future<bool> delete(int id) async {
    final result = await _db.execute(
      Sql.named('DELETE FROM products WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.affectedRows > 0; // false = nothing had that id
  }

  Future<Product> create({
    required int categoryId,
    required String name,
    required double price,
    String? description,
    String? imageUrl,
  }) async {
    final result = await _db.execute(
      Sql.named(
        'INSERT INTO products (category_id, name, description, price, image_url) '
        'VALUES (@categoryId, @name, @description, @price, @imageUrl) '
        'RETURNING $_columns',
      ),
      parameters: {
        'categoryId': categoryId,
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
      },
    );
    return _fromRow(result.first.toColumnMap());
  }

  Product _fromRow(Map<String, dynamic> row) => Product(
    id: row['id'] as int,
    categoryId: row['category_id'] as int,
    name: row['name'] as String,
    description: row['description'] as String?,
    price: double.parse(row['price'].toString()),
    imageUrl: row['image_url'] as String?,
    isAvailable: row['is_available'] as bool,
  );
}
