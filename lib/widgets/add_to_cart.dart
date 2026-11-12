import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/cart.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../routing/app_router.dart';

// Adds a book to the cart and shows what happened in a SnackBar: "Added",
// or why it could not be added (out of stock, not enough stock).
// Returns true when the book was added.
bool addToCartWithMessage(
  BuildContext context,
  WidgetRef ref,
  Product product, {
  int quantity = 1,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  try {
    ref.read(cartProvider.notifier).add(product, quantity: quantity);
    messenger.showSnackBar(
      SnackBar(
        content: Text('Added $quantity × "${product.name}" to your cart'),
        action: SnackBarAction(
          label: 'View Cart',
          onPressed: () => context.push(AppRoutes.cart),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    return true;
  } on CartException catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(error.message)));
    return false;
  }
}
