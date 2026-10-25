import 'package:flutter/foundation.dart';
import 'package:shared_models/shared_models.dart';

import '../utils/format.dart';

class CartLine {
  CartLine(this.product, this.quantity);

  final Product product;
  int quantity;

  int get totalCents => toCents(product.price) * quantity;
}

/// The cart, shared by every screen.
/// Screens "listen" to it; when it changes, they rebuild automatically.
class CartController extends ChangeNotifier {
  static const maxQuantity = 20; // the same limit as the backend

  final Map<int, CartLine> _lines = {}; // productId → line

  List<CartLine> get lines => List.unmodifiable(_lines.values);
  bool get isEmpty => _lines.isEmpty;
  int get itemCount =>
      _lines.values.fold(0, (sum, line) => sum + line.quantity);
  int get totalCents =>
      _lines.values.fold(0, (sum, line) => sum + line.totalCents);

  void add(Product product) {
    final line = _lines[product.id];
    if (line == null) {
      _lines[product.id] = CartLine(product, 1);
    } else if (line.quantity < maxQuantity) {
      line.quantity++;
    }
    notifyListeners(); // "I changed!" → every listening screen rebuilds
  }

  void setQuantity(int productId, int quantity) {
    final line = _lines[productId];
    if (line == null) return;
    if (quantity <= 0) {
      _lines.remove(productId);
    } else {
      line.quantity = quantity.clamp(1, maxQuantity);
    }
    notifyListeners();
  }

  void clear() {
    _lines.clear();
    notifyListeners();
  }
}

final cart = CartController();
