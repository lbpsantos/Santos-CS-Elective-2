import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order.dart';

// All the Supabase calls for the `orders` and `order_items` tables.
class OrderService {
  OrderService(this._supabase);

  final SupabaseClient _supabase;

  // Checkout. Calls the place_order() function in Supabase
  // (supabase/final_project.sql) with only the book ids and quantities.
  // Supabase looks up the names, prices and stock itself, saves the order
  // and its items, lowers the stock and sets the status to "done", all in
  // one transaction. If anything fails, nothing is saved and an error is
  // thrown (e.g. 'Only 2 left in stock for "Dune".').
  Future<Order> placeOrder(List<Map<String, dynamic>> items) async {
    final result = await _supabase.rpc('place_order', params: {'items': items});
    return Order.fromJson(Map<String, dynamic>.from(result as Map));
  }

  // The customer's own orders, newest first, with their items.
  // RLS would hide other customers' orders anyway; the eq() just makes the
  // query say what it means.
  Future<List<Order>> fetchMyOrders(String userId) async {
    final rows = await _supabase
        .from('orders')
        .select('*, order_items(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .order('id', ascending: false);
    return rows.map(Order.fromJson).toList();
  }

  // Every order, newest first, with the items and the customer's name.
  // Only admins get rows back (RLS).
  Future<List<Order>> fetchAllOrders() async {
    final rows = await _supabase
        .from('orders')
        .select('*, order_items(*), profiles(firstname, lastname, email)')
        .order('created_at', ascending: false)
        .order('id', ascending: false);
    return rows.map(Order.fromJson).toList();
  }

  // Admins only: change an order's status. Supabase only allows the status
  // column to be updated, and only by admins.
  Future<void> updateStatus(int orderId, OrderStatus status) async {
    final rows = await _supabase
        .from('orders')
        .update({'status': status.value})
        .eq('id', orderId)
        .select('id');
    if (rows.isEmpty) {
      throw const PostgrestException(
        message: 'Permission denied: the order was not changed.',
        code: '42501',
      );
    }
  }
}
