import 'dart:math';

import 'package:my_first_flutter_ui/models/genre.dart';
import 'package:my_first_flutter_ui/models/product.dart';
import 'package:my_first_flutter_ui/models/product_filter.dart';
import 'package:my_first_flutter_ui/models/product_page.dart';
import 'package:my_first_flutter_ui/services/product_service.dart';

const sampleGenres = [
  Genre(id: 1, name: 'Adventure'),
  Genre(id: 2, name: 'Magic'),
  Genre(id: 3, name: 'Mystery'),
];

// [count] simple books with ids 1..count. Prices go up by ₱10 per book
// (₱310, ₱320, ...), ratings go 3.5, 4.0, 4.5, 5.0, 3.5, ... and genres go
// Magic, Mystery, Adventure, Magic, ... (with 20 books: 7 Magic books).
List<Product> sampleBooks(int count) {
  return [
    for (var i = 1; i <= count; i++)
      Product(
        id: i,
        name: 'Book $i',
        author: 'Author $i',
        price: 300.0 + i * 10,
        rating: 3.5 + (i % 4) * 0.5,
        genreId: sampleGenres[i % 3].id,
        genre: sampleGenres[i % 3].name,
      ),
  ];
}

// A ProductService that keeps the books in a list instead of Supabase, so
// the provider and widget tests run without a real database.
// The real Supabase queries are tested in product_service_test.dart.
class FakeProductService implements ProductService {
  FakeProductService(List<Product> books, {this.genres = sampleGenres})
    : books = [...books];

  final List<Product> books;
  final List<Genre> genres;

  // Every fetchPage call, so tests can check what the app asked for.
  final List<({ProductFilter filter, int page})> pageRequests = [];

  // Set this to make fetchPage fail, e.g. to test the error screen.
  Object? errorToThrow;

  @override
  Future<ProductPage> fetchPage({
    required ProductFilter filter,
    required int page,
    required int pageSize,
  }) async {
    pageRequests.add((filter: filter, page: page));
    if (errorToThrow != null) throw errorToThrow!;

    final minPrice = filter.minPrice;
    final maxPrice = filter.maxPrice;
    final genreId = filter.genreId;
    final search = filter.search.toLowerCase();
    final matching =
        books
            .where((book) => genreId == null || book.genreId == genreId)
            .where((book) => minPrice == null || book.price >= minPrice)
            .where((book) => maxPrice == null || book.price <= maxPrice)
            .where((book) => book.name.toLowerCase().contains(search))
            .toList()
          ..sort((a, b) => b.id!.compareTo(a.id!)); // newest first

    // Like the real service: a page past the end shows the last page.
    final lastPage = max(1, (matching.length / pageSize).ceil());
    final shownPage = min(page, lastPage);
    return ProductPage(
      products: matching.skip((shownPage - 1) * pageSize).take(pageSize).toList(),
      page: shownPage,
      pageSize: pageSize,
      totalCount: matching.length,
    );
  }

  @override
  Future<List<Genre>> fetchGenres() async => genres;

  @override
  Future<PriceBounds?> fetchPriceBounds() async {
    if (books.isEmpty) return null;
    final prices = books.map((book) => book.price);
    return PriceBounds(min: prices.reduce(min), max: prices.reduce(max));
  }

  @override
  Future<Product?> fetchTopRated() async {
    if (books.isEmpty) return null;
    return books.reduce((best, book) {
      if (book.rating != best.rating) {
        return book.rating > best.rating ? book : best;
      }
      return book.id! > best.id! ? book : best;
    });
  }

  @override
  Future<Product> addProduct(Product product) async {
    final nextId = books.map((book) => book.id!).fold(0, max) + 1;
    final saved = _saved(product, nextId);
    books.add(saved);
    return saved;
  }

  @override
  Future<Product> updateProduct(Product product) async {
    final index = books.indexWhere((book) => book.id == product.id);
    if (index < 0) throw const ProductException('This book was not found.');
    final saved = _saved(product, product.id!);
    books[index] = saved;
    return saved;
  }

  @override
  Future<void> deleteProduct(int id) async {
    final before = books.length;
    books.removeWhere((book) => book.id == id);
    if (books.length == before) {
      throw const ProductException('Nothing was deleted.');
    }
  }

  // Like Supabase: the saved book has its id and its genre's name.
  Product _saved(Product product, int id) {
    final genreName = genres
        .where((genre) => genre.id == product.genreId)
        .map((genre) => genre.name)
        .firstOrNull;
    return Product(
      id: id,
      name: product.name,
      author: product.author,
      price: product.price,
      description: product.description,
      imageUrl: product.imageUrl,
      genreId: genreName == null ? null : product.genreId,
      genre: genreName ?? '',
      rating: product.rating,
    );
  }
}
