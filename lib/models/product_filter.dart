// The category chips on the home screen.
enum BookCategory {
  all('All Result'),
  harryPotter('Harry Potter'),
  percyJackson('Percy Jackson'),
  topRated('Top Rated');

  const BookCategory(this.label);

  // The text shown on the chip.
  final String label;
}

// Everything the customer picked to narrow down the book list.
// ProductService turns this into the Supabase query.
class ProductFilter {
  const ProductFilter({
    this.search = '',
    this.category = BookCategory.all,
    this.genreId,
    this.minPrice,
    this.maxPrice,
  });

  final String search;
  final BookCategory category;
  // The id of the chosen genre (genres table). null means all genres.
  final int? genreId;
  // null means there is no lowest or highest price limit.
  final double? minPrice;
  final double? maxPrice;

  bool get hasPriceRange => minPrice != null || maxPrice != null;

  // True when nothing is filtered, so every book is shown.
  bool get isEmpty =>
      search.isEmpty &&
      category == BookCategory.all &&
      genreId == null &&
      !hasPriceRange;

  ProductFilter copyWith({String? search, BookCategory? category}) {
    return ProductFilter(
      search: search ?? this.search,
      category: category ?? this.category,
      genreId: genreId,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  // withGenre and withPriceRange are separate from copyWith because null is
  // a real value for them (all genres / no price limit).
  ProductFilter withGenre(int? genreId) {
    return ProductFilter(
      search: search,
      category: category,
      genreId: genreId,
      minPrice: minPrice,
      maxPrice: maxPrice,
    );
  }

  ProductFilter withPriceRange(double? min, double? max) {
    return ProductFilter(
      search: search,
      category: category,
      genreId: genreId,
      minPrice: min,
      maxPrice: max,
    );
  }

  // Riverpod checks if the new filter == the old one before updating the
  // screen. Comparing the values (not the objects) means the books are only
  // loaded again when the filter really changed.
  @override
  bool operator ==(Object other) {
    return other is ProductFilter &&
        other.search == search &&
        other.category == category &&
        other.genreId == genreId &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice;
  }

  @override
  int get hashCode =>
      Object.hash(search, category, genreId, minPrice, maxPrice);
}

// The cheapest and the most expensive price in the shop.
// Used as the two ends of the price slider.
class PriceBounds {
  const PriceBounds({required this.min, required this.max});

  final double min;
  final double max;
}
