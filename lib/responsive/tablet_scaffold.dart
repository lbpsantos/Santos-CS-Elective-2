import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class TabletScaffold extends StatelessWidget {
  final List<Product> products;

  const TabletScaffold({
    super.key,
    this.products = sampleProducts,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 columns on tablet screens
        crossAxisSpacing: 18,
        mainAxisSpacing: 18,
        childAspectRatio: 0.54, // Comfortable aspect ratio for modern book cards
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
