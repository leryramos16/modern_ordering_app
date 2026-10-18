import 'package:backend/database/database.dart';
import 'package:backend/repositories/product_repository.dart';
import 'package:dart_frog/dart_frog.dart';

final _productRepository = ProductRepository(Database.pool);

Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(provider<ProductRepository>((_) => _productRepository));
}
