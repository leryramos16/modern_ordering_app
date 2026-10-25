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
}
