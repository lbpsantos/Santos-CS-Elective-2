import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class MobileScaffold extends StatelessWidget {
  // The books on the current page (from Supabase)
  final List<Product> products;

  const MobileScaffold({
    super.key,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No books found matching your search.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      // The home screen scrolls everything together (search, filters and
      // books), so the grid itself doesn't scroll. One page is only 6 books.
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 columns on mobile screens
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.42, // tall enough for the cover, text and buttons
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(
          product: product,
          onTap: () => context.push('/details', extra: product),
        );
      },
    );
  }
}
