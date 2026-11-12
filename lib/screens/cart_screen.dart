import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/cart.dart';
import '../providers/cart_provider.dart';
import '../providers/order_provider.dart';
import '../routing/app_router.dart';
import '../services/product_service.dart';
import '../widgets/product_cover.dart';
import '../widgets/state_views.dart';

// The shopping cart (customers only): change quantities, remove books, see
// the running total, and check out.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  bool _placingOrder = false;

  CartNotifier get _cart => ref.read(cartProvider.notifier);

  // Runs a cart change and shows the reason if it is not allowed
  // (e.g. more copies than the stock).
  void _change(void Function() action) {
    try {
      action();
    } on CartException catch (error) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('Remove all books from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) _cart.clear();
  }

  // Saves the order in Supabase, then opens the confirmation page.
  Future<void> _checkout() async {
    setState(() => _placingOrder = true);
    try {
      final order = await ref.read(orderActionsProvider).checkout();
      if (!mounted) return;
      // Replace the cart page, so Back goes to the shop.
      context.pushReplacement(AppRoutes.checkout, extra: order);
    } catch (error) {
      if (!mounted) return;
      setState(() => _placingOrder = false);
      final message = error is CartException
          ? error.message
          : friendlyErrorMessage(error);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.error_outline, size: 36),
          title: const Text('Order not placed'),
          content: Text(
            '$message\n\nNothing was saved and your cart was not changed.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(cartProvider);
    final count = ref.watch(cartCountProvider);
    final total = ref.watch(cartTotalProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          if (items.isNotEmpty && !_placingOrder)
            IconButton(
              tooltip: 'Clear Cart',
              icon: const Icon(Icons.remove_shopping_cart_outlined),
              onPressed: _clearAll,
            ),
        ],
      ),
      body: items.isEmpty
          ? MessageView(
              icon: Icons.shopping_bag_outlined,
              title: 'Your cart is empty',
              message: 'Browse the shop and add a book to start an order.',
              actionLabel: 'Discover Books',
              actionIcon: Icons.menu_book,
              onAction: () => context.go(AppRoutes.home),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) =>
                        _buildItem(theme, items[index]),
                  ),
                ),
                _buildSummary(theme, count, total),
              ],
            ),
    );
  }

  Widget _buildItem(ThemeData theme, CartItem item) {
    final book = item.product;
    final atStockLimit = item.quantity >= book.stock;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 55,
                height: 80,
                child: ProductCover(imageUrl: book.imageUrl, iconSize: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₱${book.price.toStringAsFixed(2)} each',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    atStockLimit
                        ? 'Max ${book.stock} (all in stock)'
                        : '${book.stock} in stock',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: atStockLimit
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₱${item.subtotal.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _placingOrder
                          ? null
                          : () => _cart.remove(book.id),
                    ),
                  ],
                ),
                // Quantity stepper
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        iconSize: 16,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        tooltip: 'Decrease quantity',
                        onPressed: _placingOrder
                            ? null
                            : () => _change(() => _cart.decrement(book.id)),
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        '${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        iconSize: 16,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        tooltip: 'Increase quantity',
                        // Can't go above the stock.
                        onPressed: _placingOrder || atStockLimit
                            ? null
                            : () => _change(() => _cart.increment(book.id)),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(ThemeData theme, int count, double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Items'),
                Text(
                  '$count ${count == 1 ? 'book' : 'books'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₱${total.toStringAsFixed(2)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Prices and stock are checked again when you check out.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                onPressed: _placingOrder ? null : _checkout,
                icon: _placingOrder
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.lock_outline),
                label: Text(
                  _placingOrder ? 'Placing order...' : 'Checkout',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
