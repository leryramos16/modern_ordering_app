import 'package:postgres/postgres.dart';
import 'package:shared_models/shared_models.dart';

class CategoryRepository {
  CategoryRepository(this._db);

  final Pool _db;

  Future<List<ProductCategory>> findAll() async {
    final result = await _db.execute(
      'SELECT id, name FROM categories ORDER BY name',
    );
    return result.map((row) {
      final map = row.toColumnMap();
      return ProductCategory(id: map['id'] as int, name: map['name'] as String);
    }).toList();
  }

  Future<bool> exists(int id) async {
    final result = await _db.execute(
      Sql.named('SELECT 1 FROM categories WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.isNotEmpty;
  }

  Future<ProductCategory?> update(int id, String name) async {
    final result = await _db.execute(
      Sql.named(
        'UPDATE categories SET name = @name WHERE id = @id RETURNING id, name',
      ),
      parameters: {'id': id, 'name': name},
    );
    if (result.isEmpty) return null;
    final row = result.first.toColumnMap();
    return ProductCategory(id: row['id'] as int, name: row['name'] as String);
  }

  Future<int> productCount(int id) async {
    final result = await _db.execute(
      Sql.named('SELECT count(*) AS n FROM products WHERE category_id = @id'),
      parameters: {'id': id},
    );
    return result.first.toColumnMap()['n'] as int;
  }

  Future<bool> delete(int id) async {
    final result = await _db.execute(
      Sql.named('DELETE FROM categories WHERE id = @id'),
      parameters: {'id': id},
    );
    return result.affectedRows > 0;
  }

  Future<ProductCategory> create(String name) async {
    final result = await _db.execute(
      Sql.named(
        'INSERT INTO categories (name) VALUES (@name) RETURNING id, name',
      ),
      parameters: {'name': name},
    );
    final row = result.first.toColumnMap();
    return ProductCategory(id: row['id'] as int, name: row['name'] as String);
  }
}
