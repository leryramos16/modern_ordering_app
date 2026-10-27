import 'package:postgres/postgres.dart';
import 'package:shared_models/shared_models.dart';

/// A problem the customer can fix (for example, an item sold out).
class OrderException implements Exception {
  OrderException(this.message);
  final String message;
}

class OrderRepository {
  OrderRepository(this._db);

  final Pool _db;

  Future<Order> create({
    required int userId,
    required Map<int, int> quantities, // productId → how many
    required String deliveryAddress,
    required String contactPhone,
    String? notes,
  }) {
    // A transaction: EVERYTHING inside is saved together, or NOTHING is.
    // If anything throws, PostgreSQL undoes all of it ("rollback").
    return _db.runTx((tx) async {
      final ids = quantities.keys.toList();

      // 1. Real prices, from OUR database. Only products still on the menu.
      final rows = await tx.execute(
        Sql.named(
          'SELECT id, name, price FROM products '
          'WHERE id = ANY(@ids) AND is_available = true',
        ),
        parameters: {'ids': TypedValue(Type.integerArray, ids)},
      );
      if (rows.length != ids.length) {
        throw OrderException(
          'Some items in your cart are no longer available. Please review your cart.',
        );
      }

      // 2. Add up the total in CENTS (whole numbers), never in doubles.
      var totalCents = 0;
      final items = <OrderItem>[];
      for (final row in rows) {
        final map = row.toColumnMap();
        final productId = map['id'] as int;
        final quantity = quantities[productId]!;
        final unitCents = (double.parse(map['price'].toString()) * 100).round();
        totalCents += unitCents * quantity;
        items.add(
          OrderItem(
            productId: productId,
            productName: map['name'] as String,
            quantity: quantity,
            unitPrice: unitCents / 100,
          ),
        );
      }

      // 3. The order itself.
      final orderResult = await tx.execute(
        Sql.named(
          'INSERT INTO orders (user_id, total, notes, delivery_address, contact_phone) '
          'VALUES (@userId, @total, @notes, @address, @phone) '
          'RETURNING id, status, created_at',
        ),
        parameters: {
          'userId': userId,
          'total': totalCents / 100,
          'notes': notes,
          'address': deliveryAddress,
          'phone': contactPhone,
        },
      );
      final orderRow = orderResult.first.toColumnMap();
      final orderId = orderRow['id'] as int;

      // 4. One row per item, with its price snapshot.
      for (final item in items) {
        await tx.execute(
          Sql.named(
            'INSERT INTO order_items (order_id, product_id, quantity, unit_price) '
            'VALUES (@orderId, @productId, @quantity, @unitPrice)',
          ),
          parameters: {
            'orderId': orderId,
            'productId': item.productId,
            'quantity': item.quantity,
            'unitPrice': item.unitPrice,
          },
        );
      }

      return Order(
        id: orderId,
        status: orderRow['status'] as String,
        total: totalCents / 100,
        deliveryAddress: deliveryAddress,
        contactPhone: contactPhone,
        notes: notes,
        createdAt: orderRow['created_at'] as DateTime,
        items: items,
      );
    });
  }

  static const _orderColumns =
      'o.id, o.status, o.total, o.notes, o.delivery_address, o.contact_phone, '
      'o.created_at, u.name AS customer_name';

  /// Newest first. (Later, with thousands of orders, you'd add pages.)
  Future<List<Order>> findRecent({int limit = 100}) =>
      _find('ORDER BY o.created_at DESC LIMIT @limit', {'limit': limit});

  /// One customer's own orders, newest first.
  Future<List<Order>> findForUser(int userId, {int limit = 50}) => _find(
    'WHERE o.user_id = @userId ORDER BY o.created_at DESC LIMIT @limit',
    {'userId': userId, 'limit': limit},
  );

  Future<Order?> findById(int id) async {
    final orders = await _find('WHERE o.id = @id', {'id': id});
    return orders.isEmpty ? null : orders.first;
  }

  /// Changes the status ONLY if it's still [from].
  /// Returns false if someone else changed it first.
  Future<bool> updateStatus(
    int id, {
    required String from,
    required String to,
  }) async {
    final result = await _db.execute(
      Sql.named(
        'UPDATE orders SET status = @to WHERE id = @id AND status = @from',
      ),
      parameters: {'id': id, 'from': from, 'to': to},
    );
    return result.affectedRows > 0;
  }

  /// [clause] is always written by US in this file, never by a user.
  Future<List<Order>> _find(
    String clause,
    Map<String, Object?> parameters,
  ) async {
    // Query 1: the orders, with the customer's name (JOIN users).
    final orderRows = await _db.execute(
      Sql.named(
        'SELECT $_orderColumns FROM orders o '
        'JOIN users u ON u.id = o.user_id $clause',
      ),
      parameters: parameters,
    );
    if (orderRows.isEmpty) return [];

    // Query 2: ALL items of ALL those orders at once, with product names.
    final ids = [for (final row in orderRows) row.toColumnMap()['id'] as int];
    final itemRows = await _db.execute(
      Sql.named(
        'SELECT oi.order_id, oi.product_id, p.name, oi.quantity, oi.unit_price '
        'FROM order_items oi JOIN products p ON p.id = oi.product_id '
        'WHERE oi.order_id = ANY(@ids) ORDER BY oi.id',
      ),
      parameters: {'ids': TypedValue(Type.integerArray, ids)},
    );

    // Group the items by their order id.
    final itemsByOrder = <int, List<OrderItem>>{};
    for (final row in itemRows) {
      final m = row.toColumnMap();
      itemsByOrder
          .putIfAbsent(m['order_id'] as int, () => [])
          .add(
            OrderItem(
              productId: m['product_id'] as int,
              productName: m['name'] as String,
              quantity: m['quantity'] as int,
              unitPrice: double.parse(m['unit_price'].toString()),
            ),
          );
    }

    return [
      for (final row in orderRows)
        _orderFromRow(row.toColumnMap(), itemsByOrder),
    ];
  }

  Order _orderFromRow(
    Map<String, dynamic> m,
    Map<int, List<OrderItem>> itemsByOrder,
  ) {
    final id = m['id'] as int;
    return Order(
      id: id,
      status: m['status'] as String,
      total: double.parse(m['total'].toString()),
      deliveryAddress: m['delivery_address'] as String,
      contactPhone: m['contact_phone'] as String,
      notes: m['notes'] as String?,
      createdAt: m['created_at'] as DateTime,
      customerName: m['customer_name'] as String,
      items: itemsByOrder[id] ?? const [],
    );
  }
}
