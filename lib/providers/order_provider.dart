import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import 'auth_provider.dart';
import 'cart_provider.dart';
import 'products_provider.dart';

// Gives the app the OrderService. The tests replace it with a fake one.
final orderServiceProvider = Provider<OrderService>(
  (ref) => OrderService(Supabase.instance.client),
);

// The customer's own orders, newest first (order history page).
// autoDispose: the orders load fresh every time the page is opened (e.g.
// after an admin changed a status), instead of keeping an old copy.
final myOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const [];
  return ref.watch(orderServiceProvider).fetchMyOrders(userId);
}, retry: (retryCount, error) => null);

// Every order, newest first (admin order list). Loads fresh every time
// the page is opened, so new customer orders show up.
final allOrdersProvider = FutureProvider.autoDispose<List<Order>>((ref) async {
  return ref.watch(orderServiceProvider).fetchAllOrders();
}, retry: (retryCount, error) => null);

// Checkout and order status changes.
final orderActionsProvider = Provider<OrderActions>(OrderActions.new);

class OrderActions {
  OrderActions(this.ref);

  final Ref ref;

  // Sends the cart to Supabase as one order. Only the book ids and the
  // quantities are sent; the prices come from the database.
  // On success the cart is emptied and the new order is returned. On
  // failure nothing was saved, and the cart stays as it is.
  Future<Order> checkout() async {
    final items = ref.read(cartProvider);
    if (items.isEmpty) throw const CartException('Your cart is empty.');

    try {
      final order = await ref
          .read(orderServiceProvider)
          .placeOrder(items.map((item) => item.toOrderJson()).toList());
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(myOrdersProvider);
      return order;
    } finally {
      // The stock changed (or the stock numbers on screen were old), so
      // load the books again either way.
      ref.invalidate(productsProvider);
    }
  }

  // Admins only: change an order's status.
  Future<void> updateStatus(Order order, OrderStatus status) async {
    await ref.read(orderServiceProvider).updateStatus(order.id, status);
    ref.invalidate(allOrdersProvider);
  }
}
