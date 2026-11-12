import 'package:my_first_flutter_ui/models/order.dart';
import 'package:my_first_flutter_ui/services/order_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'fake_product_service.dart';

// An OrderService without Supabase. placeOrder works like the place_order
// function in supabase/final_project.sql: the names and prices come from
// the books in [products] (not from the app), every stock is checked
// first, and if one check fails nothing is saved.
class FakeOrderService implements OrderService {
  FakeOrderService(this.products, {this.userId = 'user-123'});

  final FakeProductService products;
  final String userId;
  final List<Order> orders = [];
  // What the app sent to placeOrder, so tests can check it.
  final List<List<Map<String, dynamic>>> sentItems = [];

  int _nextOrderId = 1;
  int _nextItemId = 1;

  @override
  Future<Order> placeOrder(List<Map<String, dynamic>> items) async {
    sentItems.add(items);

    // 1. Check everything first (like the transaction rolling back).
    for (final item in items) {
      final book = products.books
          .where((book) => book.id == item['product_id'])
          .firstOrNull;
      if (book == null) {
        throw const PostgrestException(
          message: 'A book in your cart is no longer available.',
          code: 'P0001',
        );
      }
      if (book.stock < (item['quantity'] as int)) {
        throw PostgrestException(
          message: 'Only ${book.stock} left in stock for "${book.name}".',
          code: 'P0001',
        );
      }
    }

    // 2. Save the order with the database's names and prices, lower stock.
    final orderItems = <OrderItem>[];
    for (final item in items) {
      final index = products.books.indexWhere(
        (book) => book.id == item['product_id'],
      );
      final book = products.books[index];
      final quantity = item['quantity'] as int;
      orderItems.add(
        OrderItem(
          id: _nextItemId++,
          productId: book.id,
          productName: book.name,
          unitPrice: book.price,
          quantity: quantity,
        ),
      );
      products.books[index] = book.copyWith(stock: book.stock - quantity);
    }
    final order = Order(
      id: _nextOrderId++,
      createdAt: DateTime.now(),
      userId: userId,
      status: OrderStatus.done,
      total: orderItems.fold(0.0, (sum, item) => sum + item.subtotal),
      items: orderItems,
      customerName: 'Lucas Santos',
      customerEmail: 'lucas@example.com',
    );
    orders.add(order);
    return order;
  }

  @override
  Future<List<Order>> fetchMyOrders(String userId) async {
    return orders.where((order) => order.userId == userId).toList()
      ..sort((a, b) => b.id.compareTo(a.id)); // newest first
  }

  @override
  Future<List<Order>> fetchAllOrders() async {
    return [...orders]..sort((a, b) => b.id.compareTo(a.id));
  }

  @override
  Future<void> updateStatus(int orderId, OrderStatus status) async {
    final index = orders.indexWhere((order) => order.id == orderId);
    orders[index] = orders[index].copyWith(status: status);
  }
}
