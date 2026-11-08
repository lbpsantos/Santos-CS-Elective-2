import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_filter.dart';

// Holds the search text, category and price range that the customer picked.
class ProductFilterNotifier extends Notifier<ProductFilter> {
  @override
  ProductFilter build() => const ProductFilter();

  void setSearch(String text) {
    state = state.copyWith(search: text.trim());
  }

  void setCategory(BookCategory category) {
    state = state.copyWith(category: category);
  }

  // From the genre dropdown. null means all genres.
  void setGenre(int? genreId) {
    state = state.withGenre(genreId);
  }

  // From the price slider. null means no limit on that side.
  void setPriceRange(double? minPrice, double? maxPrice) {
    state = state.withPriceRange(minPrice, maxPrice);
  }

  void clearPriceRange() {
    state = state.withPriceRange(null, null);
  }

  // Remove every filter and show all the books again.
  void clearAll() {
    state = const ProductFilter();
  }
}

final productFilterProvider =
    NotifierProvider<ProductFilterNotifier, ProductFilter>(
      ProductFilterNotifier.new,
    );
