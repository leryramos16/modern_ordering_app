import 'dart:io';
import 'package:postgres/postgres.dart';

class Database {
  Database._();

  static final Pool pool = Pool.withUrl(
    Platform.environment['DATABASE_URL'] ??
        'postgresql://postgres:mypostgresql@localhost:5432/ordering_mobileapp'
            '?sslmode=disable&max_connection_count=10',
  );
}
