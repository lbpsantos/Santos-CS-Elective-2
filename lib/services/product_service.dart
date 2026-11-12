import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/genre.dart';
import '../models/product.dart';
import '../models/product_filter.dart';
import '../models/product_page.dart';

// All the Supabase queries for the `products` and `genres` tables.
// Reading is open to every logged-in user; adding, editing and deleting
// only works for admins (the RLS policies in supabase/final_project.sql).
class ProductService {
  ProductService(this._supabase);

  final SupabaseClient _supabase;

  static const String table = 'products';

  // Every column of the book, plus the name of its genre. "genres(name)"
  // follows genre_id to the genres table (a join), so each row comes back
  // with {'genres': {'name': 'Magic'}} inside it.
  static const String _columns = '*, genres(name)';

  // All the genres, A to Z, for the genre dropdowns.
  Future<List<Genre>> fetchGenres() async {
    final rows = await _supabase
        .from('genres')
        .select('id, name')
        .order('name', ascending: true);
    return rows.map(Genre.fromJson).toList();
  }

  // Admins only (RLS): add a genre and return it with its new id.
  Future<Genre> addGenre(String name) async {
    final row = await _supabase
        .from('genres')
        .insert({'name': name})
        .select('id, name')
        .single();
    return Genre.fromJson(row);
  }

  // Admins only (RLS): rename a genre.
  Future<Genre> renameGenre(int id, String name) async {
    final rows = await _supabase
        .from('genres')
        .update({'name': name})
        .eq('id', id)
        .select('id, name');
    if (rows.isEmpty) {
      throw const ProductException(
        'The genre was not changed. It may be gone, or only admins can '
        'change genres.',
      );
    }
    return Genre.fromJson(rows.first);
  }

  // Admins only (RLS): delete a genre. Its books keep existing, with no
  // genre (products.genre_id is set to null).
  Future<void> deleteGenre(int id) async {
    final rows = await _supabase
        .from('genres')
        .delete()
        .eq('id', id)
        .select('id');
    if (rows.isEmpty) {
      throw const ProductException(
        'Nothing was deleted. The genre may be gone, or only admins can '
        'delete genres.',
      );
    }
  }

  // Gets one page of books that match the filter.
  // This is where the pagination happens: Supabase only sends the books on
  // this page, plus how many books match in total (for the page buttons).
  Future<ProductPage> fetchPage({
    required ProductFilter filter,
    required int page,
    required int pageSize,
  }) async {
    try {
      final result = await _queryPage(filter, page, pageSize);
      // The page can be past the end, for example after deleting the only
      // book on the last page. Then the last page is shown instead.
      if (result.products.isEmpty && page > result.totalPages) {
        return _queryPage(filter, result.totalPages, pageSize);
      }
      return result;
    } on PostgrestException catch (error) {
      // When the page starts after the last book, Supabase answers with
      // "PGRST103: Requested range not satisfiable". Same fix as above.
      if (error.code != 'PGRST103') rethrow;
      final total = await _applyFilter(
        _supabase.from(table).count(CountOption.exact),
        filter,
      );
      final lastPage = max(1, (total / pageSize).ceil());
      return _queryPage(filter, lastPage, pageSize);
    }
  }

  Future<ProductPage> _queryPage(
    ProductFilter filter,
    int page,
    int pageSize,
  ) async {
    // range() counts rows from 0 and includes both ends.
    // With 6 per page: page 1 = rows 0-5, page 2 = rows 6-11, and so on.
    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;

    final response =
        await _applyFilter(_supabase.from(table).select(_columns), filter)
            // Newest books first. Every book has a different id, so the
            // order is always the same and no book shows up on two pages.
            .order('id', ascending: false)
            .range(from, to)
            // Also ask how many books match in total ("page 2 of 4").
            .count(CountOption.exact);

    return ProductPage(
      products: response.data.map(Product.fromJson).toList(),
      page: page,
      pageSize: pageSize,
      totalCount: response.count,
    );
  }

  // Adds the search, category and price filters to a query.
  PostgrestFilterBuilder<T> _applyFilter<T>(
    PostgrestFilterBuilder<T> query,
    ProductFilter filter,
  ) {
    final search = filter.search.trim();
    if (search.isNotEmpty) {
      // Commas and brackets have a special meaning inside or(), so they are
      // swapped for "_", which matches any one character.
      final text = search.replaceAll(RegExp(r'[,()"\\]'), '_');
      // Title or author contains the text. ilike ignores upper and lower
      // case, and % means "any text".
      query = query.or('name.ilike.%$text%,author.ilike.%$text%');
    }

    // The genre dropdown: only books whose genre_id is the chosen genre.
    final genreId = filter.genreId;
    if (genreId != null) query = query.eq('genre_id', genreId);

    switch (filter.category) {
      case BookCategory.all:
        break;
      case BookCategory.harryPotter:
        query = query.ilike('name', '%Harry Potter%');
      case BookCategory.percyJackson:
        query = query.ilike('author', '%Riordan%');
      case BookCategory.topRated:
        query = query.gte('rating', 4.8);
    }

    // The price slider: only books from minPrice up to maxPrice.
    final minPrice = filter.minPrice;
    final maxPrice = filter.maxPrice;
    if (minPrice != null) query = query.gte('price', minPrice);
    if (maxPrice != null) query = query.lte('price', maxPrice);

    return query;
  }

  // The cheapest and the most expensive price, used for the two ends of the
  // price slider. Returns null when the shop has no books.
  Future<PriceBounds?> fetchPriceBounds() async {
    final rows = await Future.wait([
      _supabase
          .from(table)
          .select('price')
          .order('price', ascending: true)
          .limit(1)
          .maybeSingle(),
      _supabase
          .from(table)
          .select('price')
          .order('price', ascending: false)
          .limit(1)
          .maybeSingle(),
    ]);
    final cheapest = rows[0];
    final priciest = rows[1];
    if (cheapest == null || priciest == null) return null;
    return PriceBounds(
      min: (cheapest['price'] as num).toDouble(),
      max: (priciest['price'] as num).toDouble(),
    );
  }

  // The highest rated book, for the spotlight card on the home screen.
  // If several books have the same rating, the newest one wins.
  Future<Product?> fetchTopRated() async {
    final row = await _supabase
        .from(table)
        .select(_columns)
        .order('rating', ascending: false)
        .order('id', ascending: false)
        .limit(1)
        .maybeSingle();
    return row == null ? null : Product.fromJson(row);
  }

  // Create: adds a book and returns it with the id that Supabase gave it.
  Future<Product> addProduct(Product product) async {
    final row = await _supabase
        .from(table)
        .insert(product.toJson())
        .select(_columns)
        .single();
    return Product.fromJson(row);
  }

  // Update: saves the edited book and returns the saved version.
  Future<Product> updateProduct(Product product) async {
    final rows = await _supabase
        .from(table)
        .update(product.toJson())
        .eq('id', product.id!)
        .select(_columns);
    // Supabase does not give an error when no row was changed, so we check.
    if (rows.isEmpty) {
      throw const ProductException(
        'This book was not found. It may have been deleted, or the table '
        'policies do not allow updates.',
      );
    }
    return Product.fromJson(rows.first);
  }

  // Delete: removes the book.
  Future<void> deleteProduct(int id) async {
    final rows = await _supabase
        .from(table)
        .delete()
        .eq('id', id)
        .select('id');
    if (rows.isEmpty) {
      throw const ProductException(
        'Nothing was deleted. The book may already be gone, or the table '
        'policies do not allow deleting.',
      );
    }
  }
}

// An error whose message can be shown to the user as it is.
class ProductException implements Exception {
  const ProductException(this.message);

  final String message;

  @override
  String toString() => message;
}

// Turns an error into a short message for a SnackBar or the error screen.
String friendlyErrorMessage(Object error) {
  if (error is PostgrestException) {
    switch (error.code) {
      case 'PGRST205':
      case '42P01':
        return 'A table was not found. Run supabase/products.sql and '
            'supabase/final_project.sql in the Supabase SQL Editor.';
      case 'PGRST200':
      case '42703':
      case 'PGRST202':
      case '42883':
        // A missing link between tables, column or function
        return 'The database is not fully set up yet. Run '
            'supabase/final_project.sql in the Supabase SQL Editor.';
      case '42501':
        return 'Permission denied. Your account is not allowed to do this.';
      case '23505':
        return 'That name is already used.';
    }
    return error.message;
  }
  if (error is StorageException) {
    if (error.statusCode == '403' || error.message.contains('security')) {
      return 'Permission denied. Only admins can upload covers.';
    }
    return 'Could not upload the cover: ${error.message}';
  }
  return error.toString();
}
