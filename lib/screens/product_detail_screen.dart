import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../routing/app_router.dart';
import '../widgets/add_to_cart.dart';
import '../widgets/app_bar_buttons.dart';
import '../widgets/delete_product_dialog.dart';
import '../widgets/product_cover.dart';

// One book's details.
// Admins: Edit and Delete buttons in the app bar.
// Customers: pick a quantity (up to the stock) and Add to Cart.
class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  // Local state for quantity counter
  int _quantity = 1;

  // The book shown on this screen. Replaced with the saved version after an
  // edit, so the new details show right away.
  late Product _product = widget.product;

  Future<void> _editBook() async {
    final saved = await context.push<Product>(
      AppRoutes.productForm,
      extra: _product,
    );
    if (saved != null && mounted) {
      setState(() => _product = saved);
    }
  }

  Future<void> _deleteBook() async {
    final deleted = await confirmAndDeleteProduct(context, ref, _product);
    // The book is gone, so go back to the shop.
    if (deleted && mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    }
  }

  // How many more copies can still go in the cart.
  int get _available =>
      _product.stock - ref.read(cartProvider.notifier).quantityOf(_product.id);

  void _incrementQuantity() {
    if (_quantity < _available) setState(() => _quantity++);
  }

  void _decrementQuantity() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  void _handleAddToCart() {
    final added = addToCartWithMessage(
      context,
      ref,
      _product,
      quantity: _quantity.clamp(1, _available),
    );
    if (added) setState(() => _quantity = 1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final book = _product;
    final isDark = theme.brightness == Brightness.dark;
    final isAdmin = ref.watch(isAdminProvider);
    // Rebuild when the cart changes, so the copies left are right.
    final inCart = ref
        .watch(cartProvider)
        .where((item) => item.product.id == book.id)
        .fold(0, (sum, item) => sum + item.quantity);
    final available = book.stock - inCart;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Details'),
        actions: [
          if (isAdmin) ...[
            IconButton(
              tooltip: 'Edit',
              icon: const Icon(Icons.edit_outlined),
              onPressed: _editBook,
            ),
            IconButton(
              tooltip: 'Delete',
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
              onPressed: _deleteBook,
            ),
          ] else
            const CartButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Floating 3D Book Cover with Shadow
                Container(
                  height: 260,
                  width: 175,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(4, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ProductCover(imageUrl: book.imageUrl, iconSize: 64),
                  ),
                ),
                const SizedBox(height: 20),

                // Book Title
                Text(
                  book.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),

                // Author
                Text(
                  'by ${book.author}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // Metadata Info Row (Rating, Genre, Format)
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    _buildInfoBadge(
                      icon: Icons.star,
                      iconColor: Colors.amber,
                      label: book.rating > 0 ? '${book.rating}' : 'New',
                      subtitle: 'Rating',
                      theme: theme,
                    ),
                    _buildInfoBadge(
                      icon: Icons.auto_stories,
                      iconColor: theme.colorScheme.primary,
                      label: book.genre.isEmpty
                          ? 'None'
                          : book.genre.split('/').first.trim(),
                      subtitle: 'Genre',
                      theme: theme,
                    ),
                    _buildInfoBadge(
                      icon: Icons.inventory_2_outlined,
                      iconColor: book.inStock
                          ? Colors.green
                          : theme.colorScheme.error,
                      label: book.inStock ? '${book.stock}' : 'None',
                      subtitle: 'In stock',
                      theme: theme,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Price display
                Text(
                  '₱${book.price.toStringAsFixed(2)}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Synopsis Section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF26211E)
                        : const Color(0xFFF3EFE9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Synopsis',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        book.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (!isAdmin) ..._buildBuyBox(theme, book, inCart, available),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Customers only: the quantity picker and the Add to Cart button.
  List<Widget> _buildBuyBox(
    ThemeData theme,
    Product book,
    int inCart,
    int available,
  ) {
    if (available <= 0) {
      return [
        Text(
          book.inStock
              ? 'All $inCart copies in stock are already in your cart.'
              : 'This book is out of stock.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: theme.colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (inCart > 0)
          TextButton(
            onPressed: () => context.push(AppRoutes.cart),
            child: const Text('View Shopping Cart'),
          ),
      ];
    }
    final quantity = _quantity.clamp(1, available);
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Quantity:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(width: 16),
          IconButton.filledTonal(
            onPressed: quantity > 1 ? _decrementQuantity : null,
            icon: const Icon(Icons.remove, size: 18),
            tooltip: 'Decrease quantity',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '$quantity',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton.filledTonal(
            onPressed: quantity < available ? _incrementQuantity : null,
            icon: const Icon(Icons.add, size: 18),
            tooltip: 'Increase quantity',
          ),
        ],
      ),
      if (inCart > 0)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '$inCart already in your cart · $available more available',
            style: theme.textTheme.bodySmall,
          ),
        ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
          ),
          onPressed: _handleAddToCart,
          icon: const Icon(Icons.shopping_bag_outlined),
          label: Text(
            'Add to Cart • ₱${(book.price * quantity).toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      const SizedBox(height: 12),
      TextButton(
        onPressed: () => context.push(AppRoutes.cart),
        child: const Text('View Shopping Cart'),
      ),
    ];
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required ThemeData theme,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF26211E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
