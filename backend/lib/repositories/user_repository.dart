import 'package:postgres/postgres.dart';
import 'package:shared_models/shared_models.dart';

class UserRepository {
  UserRepository(this._db);

  final Pool _db;

  static const _columns = 'id, name, email, role';

  Future<User?> findById(int id) async {
    final result = await _db.execute(
      Sql.named('SELECT $_columns FROM users WHERE id = @id'),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return _fromRow(result.first.toColumnMap());
  }

  /// Used by login: returns the user together with the stored hash.
  Future<({User user, String passwordHash})?> findByEmail(String email) async {
    final result = await _db.execute(
      Sql.named(
        'SELECT $_columns, password_hash FROM users WHERE email = @email',
      ),
      parameters: {'email': email},
    );
    if (result.isEmpty) return null;
    final row = result.first.toColumnMap();
    return (user: _fromRow(row), passwordHash: row['password_hash'] as String);
  }

  Future<User> create({
    required String name,
    required String email,
    required String passwordHash,
  }) async {
    final result = await _db.execute(
      Sql.named(
        'INSERT INTO users (name, email, password_hash) '
        'VALUES (@name, @email, @hash) RETURNING $_columns',
      ),
      parameters: {'name': name, 'email': email, 'hash': passwordHash},
    );
    return _fromRow(result.first.toColumnMap());
  }

  User _fromRow(Map<String, dynamic> row) => User(
    id: row['id'] as int,
    name: row['name'] as String,
    email: row['email'] as String,
    role: row['role'] as String,
  );
}
