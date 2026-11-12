import 'product.dart';

// One book in the shopping cart, with how many copies the customer wants.
// The cart itself lives in cartProvider (lib/providers/cart_provider.dart).
class CartItem {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get subtotal => product.price * quantity;

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  // What place_order() in Supabase needs: only the id and the quantity.
  // The price and the name are looked up in the database at checkout.
  Map<String, dynamic> toOrderJson() {
    return {'product_id': product.id, 'quantity': quantity};
  }
}

// Thrown by the cart when a book is out of stock or the quantity would go
// above the stock. The message can be shown to the customer as it is.
class CartException implements Exception {
  const CartException(this.message);

  final String message;

  @override
  String toString() => message;
}
