import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import 'delete_product_dialog.dart';
import 'product_cover.dart';
import 'product_form_sheet.dart';

// Displays an individual eBook in the modern card style (StatelessWidget for static display)
// The ⋮ menu on the card is used to edit or delete the book.
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: rating tag and the edit / delete menu
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 12, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(
                          // Books added without a rating show "New"
                          product.rating > 0 ? '${product.rating}' : 'New',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _ProductMenu(product: product),
                ],
              ),
              const SizedBox(height: 4),

              // Book Cover Image with realistic 3D book shadow
              Expanded(
                child: Center(
                  child: AspectRatio(
                    // Every cover has the shape of a book
                    aspectRatio: 2 / 3,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
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

              // Book Title
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

              // Author
              Text(
                'by ${product.author}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Price badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '₱${product.price.toStringAsFixed(2)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Book',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _MenuChoice { edit, delete }

// The ⋮ button on a card, with Edit and Delete.
class _ProductMenu extends ConsumerWidget {
  const _ProductMenu({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: 32,
      height: 32,
      child: PopupMenuButton<_MenuChoice>(
        tooltip: 'Edit or delete',
        padding: EdgeInsets.zero,
        iconSize: 20,
        icon: const Icon(Icons.more_vert),
        onSelected: (choice) {
          switch (choice) {
            case _MenuChoice.edit:
              showProductForm(context, product: product);
            case _MenuChoice.delete:
              confirmAndDeleteProduct(context, ref, product);
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: _MenuChoice.edit,
            child: ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('Edit'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
          PopupMenuItem(
            value: _MenuChoice.delete,
            child: ListTile(
              leading: Icon(Icons.delete_outline),
              title: Text('Delete'),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}
