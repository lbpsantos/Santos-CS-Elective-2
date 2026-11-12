import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../routing/app_router.dart';
import 'add_to_cart.dart';
import 'delete_product_dialog.dart';
import 'product_cover.dart';

// One book in the grid.
// Admins see Edit and Delete buttons; customers see Add to Cart instead.
class ProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isAdmin = ref.watch(isAdminProvider);

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: rating tag and stock tag
              // Both tags shrink a little on very narrow cards.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _RatingTag(rating: product.rating),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: StockTag(stock: product.stock),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Book cover with a book-like shadow
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 8,
                            offset: const Offset(2, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ProductCover(imageUrl: product.imageUrl),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Text(
                product.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                'by ${product.author}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '₱${product.price.toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              if (isAdmin)
                _AdminButtons(product: product)
              else
                _AddToCartButton(product: product),
            ],
          ),
        ),
      ),
    );
  }
}

// Edit and Delete (admins only).
class _AdminButtons extends ConsumerWidget {
  const _AdminButtons({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    void edit() => context.push(AppRoutes.productForm, extra: product);
    void delete() => confirmAndDeleteProduct(context, ref, product);
    final deleteStyle = _compact.copyWith(
      foregroundColor: WidgetStatePropertyAll(colors.error),
    );

    // On narrow cards (phones) there is no room for the icons, so the
    // buttons show only the word. The words never wrap ("Delet / e").
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 180;
        return Row(
          children: [
            Expanded(
              child: _AdminButton(
                label: 'Edit',
                icon: Icons.edit_outlined,
                showIcon: !narrow,
                style: _compact,
                onPressed: edit,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _AdminButton(
                label: 'Delete',
                icon: Icons.delete_outline,
                showIcon: !narrow,
                style: deleteStyle,
                onPressed: delete,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AdminButton extends StatelessWidget {
  const _AdminButton({
    required this.label,
    required this.icon,
    required this.showIcon,
    required this.style,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool showIcon;
  final ButtonStyle style;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    );
    if (!showIcon) {
      return OutlinedButton(style: style, onPressed: onPressed, child: text);
    }
    return OutlinedButton.icon(
      style: style,
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: text,
    );
  }
}

// Add to Cart (customers only). Disabled when the book is out of stock.
class _AddToCartButton extends ConsumerWidget {
  const _AddToCartButton({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        onPressed: product.inStock
            ? () => addToCartWithMessage(context, ref, product)
            : null,
        icon: Icon(
          product.inStock ? Icons.add_shopping_cart : Icons.block,
          size: 16,
        ),
        label: Text(product.inStock ? 'Add to Cart' : 'Sold Out'),
      ),
    );
  }
}

final ButtonStyle _compact = OutlinedButton.styleFrom(
  visualDensity: VisualDensity.compact,
  padding: const EdgeInsets.symmetric(horizontal: 4),
  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
);

class _RatingTag extends StatelessWidget {
  const _RatingTag({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 12, color: Colors.amber),
          const SizedBox(width: 3),
          Text(
            // Books added without a rating show "New"
            rating > 0 ? '$rating' : 'New',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }
}

// "12 left" in the theme color, or "Out of stock" in red.
class StockTag extends StatelessWidget {
  const StockTag({super.key, required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final out = stock <= 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: out ? colors.errorContainer : colors.primaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        out ? 'Out of stock' : '$stock left',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: out ? colors.onErrorContainer : colors.onPrimaryContainer,
        ),
      ),
    );
  }
}
