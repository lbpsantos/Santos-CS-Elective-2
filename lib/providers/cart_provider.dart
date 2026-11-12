import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../models/product.dart';
import 'auth_provider.dart';

// The shopping cart, kept in app state. It stays the same when the customer
// moves between screens, and starts empty again when the user logs out or
// another user logs in (it watches the user id).
//
// The stock checks here are only to help the customer. Supabase checks the
// stock again at checkout (place_order), with the real numbers.
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    ref.watch(currentUserIdProvider);
    return const [];
  }

  int _indexOf(int? productId) =>
      state.indexWhere((item) => item.product.id == productId);

  int quantityOf(int? productId) {
    final index = _indexOf(productId);
    return index < 0 ? 0 : state[index].quantity;
  }

  // Add [quantity] copies of a book. Throws a CartException if the book is
  // out of stock or the cart would have more copies than the stock.
  void add(Product product, {int quantity = 1}) {
    if (!product.inStock) {
      throw CartException('"${product.name}" is out of stock.');
    }
    final index = _indexOf(product.id);
    final current = index < 0 ? 0 : state[index].quantity;
    if (current + quantity > product.stock) {
      throw CartException(
        'Only ${product.stock} ${product.stock == 1 ? 'copy' : 'copies'} '
        'of "${product.name}" ${product.stock == 1 ? 'is' : 'are'} in stock.',
      );
    }
    if (index < 0) {
      state = [...state, CartItem(product: product, quantity: quantity)];
    } else {
      state = [
        for (final item in state)
          item.product.id == product.id
              ? item.copyWith(product: product, quantity: current + quantity)
              : item,
      ];
    }
  }

  // Set a book's quantity. 0 or less removes it from the cart.
  void setQuantity(int? productId, int quantity) {
    final index = _indexOf(productId);
    if (index < 0) return;
    if (quantity <= 0) return remove(productId);
    final product = state[index].product;
    if (quantity > product.stock) {
      throw CartException(
        'Only ${product.stock} of "${product.name}" in stock.',
      );
    }
    state = [
      for (final item in state)
        item.product.id == productId ? item.copyWith(quantity: quantity) : item,
    ];
  }

  void increment(int? productId) =>
      setQuantity(productId, quantityOf(productId) + 1);

  void decrement(int? productId) =>
      setQuantity(productId, quantityOf(productId) - 1);

  void remove(int? productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  // After a successful order.
  void clear() => state = const [];
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

// How many books are in the cart (counting copies), for the cart badge.
final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartProvider).fold(0, (sum, item) => sum + item.quantity),
);

// The running total of the cart.
final cartTotalProvider = Provider<double>(
  (ref) => ref.watch(cartProvider).fold(0.0, (sum, item) => sum + item.subtotal),
);
