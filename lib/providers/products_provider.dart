import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart.dart';
import '../models/genre.dart';
import '../models/product.dart';
import '../models/product_filter.dart';
import '../models/product_page.dart';
import '../services/product_service.dart';
import 'filter_provider.dart';
import 'pagination_provider.dart';

// Gives the app the ProductService. The tests replace it with a fake one, so
// they don't need a real Supabase project.
final productServiceProvider = Provider<ProductService>(
  (ref) => ProductService(Supabase.instance.client),
);

// The books on the current page, loaded from Supabase.
// It watches the filter and the page number, so the query runs again by
// itself whenever the customer moves the price slider, searches, picks a
// category or changes the page.
final productsProvider = FutureProvider<ProductPage>(
  (ref) {
    final filter = ref.watch(productFilterProvider);
    final page = ref.watch(currentPageProvider);
    return ref
        .watch(productServiceProvider)
        .fetchPage(filter: filter, page: page, pageSize: productsPerPage);
  },
  // Riverpod 3 retries failed providers automatically. We turn that off so
  // the error message shows right away and the user can press Retry.
  retry: (retryCount, error) => null,
);

// The cheapest and the most expensive price, for the price slider.
final priceBoundsProvider = FutureProvider<PriceBounds?>(
  (ref) => ref.watch(productServiceProvider).fetchPriceBounds(),
  retry: (retryCount, error) => null,
);

// The highest rated book, for the spotlight card.
final featuredProductProvider = FutureProvider<Product?>(
  (ref) => ref.watch(productServiceProvider).fetchTopRated(),
  retry: (retryCount, error) => null,
);

// All the genres from the genres table, for the genre dropdowns.
final genresProvider = FutureProvider<List<Genre>>(
  (ref) => ref.watch(productServiceProvider).fetchGenres(),
  retry: (retryCount, error) => null,
);

// Add, edit and delete books.
//
// This is kept apart from productsProvider on purpose. productsProvider
// rebuilds whenever the page or the filter changes, and Riverpod stops a
// provider's old code from running after it rebuilds. ProductActions never
// rebuilds, so a save can't get cut off halfway.
final productActionsProvider = Provider<ProductActions>(ProductActions.new);

class ProductActions {
  ProductActions(this.ref);

  final Ref ref;

  Future<Product> addProduct(Product product) async {
    final saved = await ref.read(productServiceProvider).addProduct(product);
    // New books are listed first, so go to page 1 where the new book is.
    ref.read(currentPageProvider.notifier).goToPage(1);
    _reloadShop();
    return saved;
  }

  Future<Product> updateProduct(Product product) async {
    final saved = await ref.read(productServiceProvider).updateProduct(product);
    // Show the new title and price in the cart too.
    updateCartProduct(saved);
    _reloadShop();
    return saved;
  }

  Future<void> deleteProduct(Product product) async {
    await ref.read(productServiceProvider).deleteProduct(product.id!);
    // A deleted book can't stay in the cart.
    removeCartItem(product.id);
    _reloadShop();
  }

  // Load the books, the slider's prices and the spotlight book again, so the
  // screen matches what is in Supabase now.
  void _reloadShop() {
    ref.invalidate(productsProvider);
    ref.invalidate(priceBoundsProvider);
    ref.invalidate(featuredProductProvider);
  }
}
