import 'package:postgres/postgres.dart';
import 'package:shared_models/shared_models.dart';

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
