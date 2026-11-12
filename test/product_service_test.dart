import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_first_flutter_ui/models/product.dart';
import 'package:my_first_flutter_ui/models/product_filter.dart';
import 'package:my_first_flutter_ui/services/product_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// These tests check the exact requests that ProductService sends to
// Supabase. A fake HTTP client answers instead of a real Supabase project.
void main() {
  late List<http.Request> requests;

  // A ProductService whose requests are answered by [reply].
  ProductService serviceThatReplies(
    Future<http.Response> Function(http.Request request) reply,
  ) {
    requests = [];
    final supabase = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
      httpClient: MockClient((request) async {
        requests.add(request);
        final response = await reply(request);
        // The Supabase client reads the request back from the response.
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          request: request,
        );
      }),
    );
    addTearDown(supabase.dispose);
    return ProductService(supabase);
  }

  http.Response jsonReply(
    Object body, {
    int status = 200,
    String? contentRange,
  }) {
    return http.Response(
      jsonEncode(body),
      status,
      headers: {
        'content-type': 'application/json',
        'content-range': ?contentRange,
      },
    );
  }

  Map<String, dynamic> bookRow(int id, num price) => {
    'id': id,
    'created_at': '2026-11-08T00:00:00+00:00',
    'name': 'Book $id',
    'author': 'Author',
    'price': price,
    'description': '',
    'image_url': null,
    'genre_id': 5,
    // The genre's name, joined in from the genres table
    'genres': {'name': 'Magic'},
    'rating': 4.5,
  };

  test('fetchPage asks for one page of books in the price range', () async {
    final service = serviceThatReplies(
      (request) async => jsonReply(
        [bookRow(8, 450), bookRow(7, 520.5)],
        status: 206,
        contentRange: '6-7/8',
      ),
    );

    final page = await service.fetchPage(
      filter: const ProductFilter(minPrice: 400, maxPrice: 600),
      page: 2,
      pageSize: 6,
    );

    final request = requests.single;
    expect(request.method, 'GET');
    expect(request.url.path, '/rest/v1/products');
    // Every column plus the genre's name from the genres table
    expect(request.url.queryParameters['select'], '*,genres(name)');
    // Page 2 with 6 per page = skip 6 rows, take 6 rows
    expect(request.url.queryParameters['offset'], '6');
    expect(request.url.queryParameters['limit'], '6');
    expect(request.url.queryParameters['order'], 'id.desc.nullslast');
    // The price slider's range
    expect(request.url.queryParametersAll['price'], ['gte.400.0', 'lte.600.0']);
    // Ask Supabase for the total count too
    expect(request.headers['Prefer'], contains('count=exact'));

    expect(page.page, 2);
    expect(page.totalCount, 8);
    expect(page.totalPages, 2);
    expect(page.products.map((book) => book.id), [8, 7]);
    expect(page.products.last.price, 520.5);
    expect(page.products.first.genreId, 5);
    expect(page.products.first.genre, 'Magic');
    expect(page.firstItemNumber, 7);
    expect(page.lastItemNumber, 8);
  });

  test('search, category and genre are added to the query', () async {
    final service = serviceThatReplies(
      (request) async => jsonReply([], contentRange: '*/0'),
    );

    await service.fetchPage(
      filter: const ProductFilter(
        search: 'sea, (monsters)',
        category: BookCategory.percyJackson,
        genreId: 3,
      ),
      page: 1,
      pageSize: 6,
    );

    final query = requests.single.url.queryParameters;
    // Commas and brackets would break or(), so they become "_"
    expect(
      query['or'],
      '(name.ilike.%sea_ _monsters_%,author.ilike.%sea_ _monsters_%)',
    );
    expect(query['author'], 'ilike.%Riordan%');
    expect(query['genre_id'], 'eq.3');
    expect(query.containsKey('price'), isFalse);
  });

  test('fetchGenres loads the genres A to Z', () async {
    final service = serviceThatReplies(
      (request) async => jsonReply([
        {'id': 1, 'name': 'Adventure'},
        {'id': 5, 'name': 'Magic'},
      ]),
    );

    final genres = await service.fetchGenres();

    final url = requests.single.url;
    expect(url.path, '/rest/v1/genres');
    expect(url.queryParameters['select'], 'id,name');
    expect(url.queryParameters['order'], 'name.asc.nullslast');
    expect(genres.map((genre) => genre.name), ['Adventure', 'Magic']);
    expect(genres.last.id, 5);
  });

  test('a page past the end shows the last page instead', () async {
    final service = serviceThatReplies((request) async {
      if (request.method == 'HEAD') {
        // The count-only query
        return http.Response('', 200, headers: {'content-range': '0-7/8'});
      }
      if (request.url.queryParameters['offset'] == '12') {
        // What Supabase answers when page 3 starts after the last book
        return jsonReply({
          'code': 'PGRST103',
          'message': 'Requested range not satisfiable',
          'details': 'An offset of 12 was requested, but there are only 8 rows.',
          'hint': null,
        }, status: 416);
      }
      return jsonReply(
        [bookRow(2, 320), bookRow(1, 310)],
        status: 206,
        contentRange: '6-7/8',
      );
    });

    final page = await service.fetchPage(
      filter: const ProductFilter(),
      page: 3,
      pageSize: 6,
    );

    expect(page.page, 2);
    expect(page.products, hasLength(2));
    expect(requests.map((request) => request.method), ['GET', 'HEAD', 'GET']);
    expect(requests.last.url.queryParameters['offset'], '6');
  });

  test('fetchPriceBounds reads the cheapest and priciest book', () async {
    final service = serviceThatReplies((request) async {
      final cheapestFirst =
          request.url.queryParameters['order'] == 'price.asc.nullslast';
      return jsonReply([
        {'price': cheapestFirst ? 299 : 699.5},
      ]);
    });

    final bounds = await service.fetchPriceBounds();

    expect(bounds!.min, 299);
    expect(bounds.max, 699.5);
  });

  test('addProduct sends the columns and reads back the new id', () async {
    final service = serviceThatReplies(
      (request) async => jsonReply(bookRow(21, 399), status: 201),
    );

    final saved = await service.addProduct(
      const Product(
        name: 'Book 21',
        author: 'Author',
        price: 399,
        genreId: 5,
        stock: 7,
      ),
    );

    final request = requests.single;
    expect(request.method, 'POST');
    final sent = jsonDecode(request.body) as Map<String, dynamic>;
    expect(sent.containsKey('id'), isFalse); // Supabase makes the id
    expect(sent['name'], 'Book 21');
    expect(sent['price'], 399);
    expect(sent['image_url'], isNull);
    expect(sent['stock'], 7);
    // The genre is saved by its id; the name stays in the genres table
    expect(sent['genre_id'], 5);
    expect(sent.containsKey('genre'), isFalse);
    // The saved book comes back with its genre's name
    expect(request.url.queryParameters['select'], '*,genres(name)');
    expect(saved.id, 21);
    expect(saved.genre, 'Magic');
  });

  test('updateProduct and deleteProduct target the book by id', () async {
    final service = serviceThatReplies((request) async {
      if (request.method == 'PATCH') return jsonReply([bookRow(5, 999)]);
      return jsonReply([
        {'id': 5},
      ]);
    });

    final saved = await service.updateProduct(
      const Product(id: 5, name: 'Book 5', author: 'Author', price: 999),
    );
    await service.deleteProduct(5);

    expect(requests.map((request) => request.method), ['PATCH', 'DELETE']);
    for (final request in requests) {
      expect(request.url.queryParameters['id'], 'eq.5');
    }
    expect(saved.price, 999);
  });

  test('deleting a book that is not there gives a clear error', () async {
    final service = serviceThatReplies((request) async => jsonReply([]));

    await expectLater(
      service.deleteProduct(99),
      throwsA(
        isA<ProductException>().having(
          (error) => error.message,
          'message',
          contains('Nothing was deleted'),
        ),
      ),
    );
  });

  test('a missing table gives a hint about the SQL file', () {
    const error = PostgrestException(
      message: "Could not find the table 'public.products' in the schema cache",
      code: 'PGRST205',
    );

    expect(friendlyErrorMessage(error), contains('supabase/products.sql'));
  });

  test('genres can be added, renamed and deleted by id', () async {
    final service = serviceThatReplies((request) async {
      if (request.method == 'POST') {
        return jsonReply({'id': 8, 'name': 'Sci-Fi'}, status: 201);
      }
      if (request.method == 'PATCH') {
        return jsonReply([
          {'id': 8, 'name': 'Space'},
        ]);
      }
      return jsonReply([
        {'id': 8},
      ]);
    });

    final added = await service.addGenre('Sci-Fi');
    final renamed = await service.renameGenre(8, 'Space');
    await service.deleteGenre(8);

    expect(requests.map((request) => request.url.path).toSet(), {
      '/rest/v1/genres',
    });
    expect(requests.map((request) => request.method), [
      'POST',
      'PATCH',
      'DELETE',
    ]);
    expect(jsonDecode(requests.first.body), {'name': 'Sci-Fi'});
    expect(requests[1].url.queryParameters['id'], 'eq.8');
    expect(added.id, 8);
    expect(renamed.name, 'Space');
  });

  test('a blocked change explains it is a permission problem', () {
    const error = PostgrestException(
      message: 'new row violates row-level security policy',
      code: '42501',
    );

    expect(friendlyErrorMessage(error), contains('Permission denied'));
  });
}
