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
}
