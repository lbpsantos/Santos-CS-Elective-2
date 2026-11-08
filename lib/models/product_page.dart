import 'dart:math';

import 'product.dart';

// One page of books from Supabase, plus what the page buttons need to know.
class ProductPage {
  const ProductPage({
    required this.products,
    required this.page,
    required this.pageSize,
    required this.totalCount,
  });

  // The books on this page (pageSize or fewer).
  final List<Product> products;
  // The page number. The first page is 1.
  final int page;
  final int pageSize;
  // How many books match the filter, counting every page.
  final int totalCount;

  // Always at least 1, so an empty result still shows "page 1 of 1".
  int get totalPages => max(1, (totalCount / pageSize).ceil());

  bool get hasPreviousPage => page > 1;
  bool get hasNextPage => page < totalPages;

  // For the "Showing 7-12 of 20 books" text.
  int get firstItemNumber => products.isEmpty ? 0 : (page - 1) * pageSize + 1;
  int get lastItemNumber =>
      products.isEmpty ? 0 : firstItemNumber + products.length - 1;
}
