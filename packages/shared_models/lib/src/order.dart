class OrderItem {
  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice; // the price AT THE TIME of ordering

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: json['productId'] as int,
    productName: json['productName'] as String,
    quantity: json['quantity'] as int,
    unitPrice: (json['unitPrice'] as num).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'productName': productName,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };
}

class Order {
  const Order({
    required this.id,
    required this.status,
    required this.total,
    required this.deliveryAddress,
    required this.contactPhone,
    required this.createdAt,
    required this.items,
    this.notes,
    this.customerName,
  });

  final int id;
  final String status;
  final double total;
  final String deliveryAddress;
  final String contactPhone;
  final String? notes;
  final String? customerName;
  final DateTime createdAt;
  final List<OrderItem> items;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as int,
    status: json['status'] as String,
    total: (json['total'] as num).toDouble(),
    deliveryAddress: json['deliveryAddress'] as String,
    contactPhone: json['contactPhone'] as String,
    notes: json['notes'] as String?,
    customerName: json['customerName'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    items: (json['items'] as List<dynamic>)
        .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status,
    'total': total,
    'deliveryAddress': deliveryAddress,
    'contactPhone': contactPhone,
    'notes': notes,
    'customerName': customerName,
    'createdAt': createdAt.toIso8601String(), // dates travel as text in JSON
    'items': items.map((i) => i.toJson()).toList(),
  };
}
