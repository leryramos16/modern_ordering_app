import 'package:backend/auth/jwt_service.dart';
import 'package:backend/database/database.dart';

import 'package:backend/repositories/category_repository.dart';
import 'package:backend/repositories/order_repository.dart';
import 'package:backend/repositories/product_repository.dart';
import 'package:backend/repositories/user_repository.dart';
import 'package:dart_frog/dart_frog.dart';

final _productRepository = ProductRepository(Database.pool);
final _userRepository = UserRepository(Database.pool);
final _categoryRepository = CategoryRepository(Database.pool);
final _orderRepository = OrderRepository(Database.pool);
final _jwtService = JwtService();

Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(provider<ProductRepository>((_) => _productRepository))
      .use(provider<UserRepository>((_) => _userRepository))
      .use(provider<CategoryRepository>((_) => _categoryRepository))
      .use(provider<OrderRepository>((_) => _orderRepository))
      .use(provider<JwtService>((_) => _jwtService));
}
