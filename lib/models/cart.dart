import 'product.dart';

// Represents an item in the shopping cart with its quantity
class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  // Calculate subtotal for this item
  double get subtotal => product.price * quantity;
}

// Simple in-memory cart list (pure Dart, no external state management packages)
final List<CartItem> cartItems = [];

// Helper functions for cart calculations
int get totalCartCount =>
    cartItems.fold(0, (sum, item) => sum + item.quantity);

double get totalCartPrice =>
    cartItems.fold(0.0, (sum, item) => sum + item.subtotal);

// Add book to cart or increase quantity if already present
void addToCart(Product product, int quantity) {
  final index = cartItems.indexWhere((item) => item.product.id == product.id);
  if (index >= 0) {
    cartItems[index].quantity += quantity;
  } else {
    cartItems.add(CartItem(product: product, quantity: quantity));
  }
}

// Increase quantity of a book
void incrementCartItem(String productId) {
  final index = cartItems.indexWhere((item) => item.product.id == productId);
  if (index >= 0) {
    cartItems[index].quantity++;
  }
}

// Decrease quantity or remove if it hits 0
void decrementCartItem(String productId) {
  final index = cartItems.indexWhere((item) => item.product.id == productId);
  if (index >= 0) {
    if (cartItems[index].quantity > 1) {
      cartItems[index].quantity--;
    } else {
      cartItems.removeAt(index);
    }
  }
}

// Remove an item completely
void removeCartItem(String productId) {
  cartItems.removeWhere((item) => item.product.id == productId);
}

// Clear all cart items upon checkout
void clearCart() {
  cartItems.clear();
}
