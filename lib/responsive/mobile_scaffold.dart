import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';

class MobileScaffold extends StatelessWidget {
  final List<Product> products;

  const MobileScaffold({
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 columns on mobile screens
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.48, // Roomy aspect ratio preventing any vertical overflow
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
