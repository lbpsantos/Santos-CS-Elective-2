// A saved order (one row in `orders`) with its items (`order_items`).
// Orders are made by the place_order() function in Supabase
// (supabase/final_project.sql); the app only reads them.

// The three values the orders.status column allows.
enum OrderStatus {
  pending('pending', 'Pending'),
  done('done', 'Done'),
  cancelled('cancelled', 'Cancelled');

  const OrderStatus(this.value, this.label);

  // The text saved in the database.
  final String value;
  // The text shown on screen.
  final String label;

  static OrderStatus fromValue(String? value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OrderStatus.pending,
    );
  }
}

// One line of an order. product_name and unit_price are a snapshot taken
// at checkout, so the order still shows the right name and price after the
// book is edited or deleted (then productId is null).
class OrderItem {
  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.unitPrice,
    required this.quantity,
  });

  final int id;
  final int? productId;
  final String productName;
  final double unitPrice;
  final int quantity;

  double get subtotal => unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as int,
      productId: json['product_id'] as int?,
      productName: json['product_name'] as String? ?? '',
      unitPrice: (json['unit_price'] as num).toDouble(),
      quantity: (json['quantity'] as num).toInt(),
    );
  }
}

class Order {
  const Order({
    required this.id,
    required this.createdAt,
    required this.userId,
    required this.status,
    required this.total,
    required this.items,
    this.customerName = '',
    this.customerEmail = '',
  });

  final int id;
  final DateTime createdAt;
  final String userId;
  final OrderStatus status;
  final double total;
  final List<OrderItem> items;
  // Only filled in for the admin's order list (joined from profiles).
  final String customerName;
  final String customerEmail;

  // Shown on the confirmation page and in the order lists.
  String get orderNumber => '#${id.toString().padLeft(5, '0')}';

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  // The row looks like {..., 'order_items': [...], 'profiles': {...}}
  // because OrderService asks for the items (and, for admins, the customer)
  // together with the order.
  factory Order.fromJson(Map<String, dynamic> json) {
    final itemRows = (json['order_items'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final profile = json['profiles'] as Map<String, dynamic>?;
    final firstName = profile?['firstname'] as String? ?? '';
    final lastName = profile?['lastname'] as String? ?? '';
    return Order(
      id: json['id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      userId: json['user_id'] as String,
      status: OrderStatus.fromValue(json['status'] as String?),
      total: (json['total'] as num).toDouble(),
      items: itemRows.map(OrderItem.fromJson).toList(),
      customerName: '$firstName $lastName'.trim(),
      customerEmail: profile?['email'] as String? ?? '',
    );
  }

  Order copyWith({OrderStatus? status}) {
    return Order(
      id: id,
      createdAt: createdAt,
      userId: userId,
      status: status ?? this.status,
      total: total,
      items: items,
      customerName: customerName,
      customerEmail: customerEmail,
    );
  }
}
