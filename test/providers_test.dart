import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_ui/models/cart.dart';
import 'package:my_first_flutter_ui/models/product.dart';
import 'package:my_first_flutter_ui/models/product_filter.dart';
import 'package:my_first_flutter_ui/providers/auth_provider.dart';
import 'package:my_first_flutter_ui/providers/cart_provider.dart';
import 'package:my_first_flutter_ui/providers/filter_provider.dart';
import 'package:my_first_flutter_ui/providers/order_provider.dart';
import 'package:my_first_flutter_ui/providers/pagination_provider.dart';
import 'package:my_first_flutter_ui/providers/products_provider.dart';
import 'package:my_first_flutter_ui/widgets/price_range_filter.dart';

import 'fake_auth_service.dart';
import 'fake_order_service.dart';
import 'fake_product_service.dart';
import 'fake_profile_service.dart';

// Tests for the Riverpod state: pages, filters, add / edit / delete, the
// cart and checkout.
void main() {
  late FakeProductService service;
  late FakeAuthService auth;
  late FakeOrderService orders;
  late ProviderContainer container;

  setUp(() {
    service = FakeProductService(sampleBooks(20));
    auth = FakeAuthService(fakeSession());
    orders = FakeOrderService(service);
    container = ProviderContainer.test(
      overrides: [
        productServiceProvider.overrideWithValue(service),
        authServiceProvider.overrideWithValue(auth),
        profileServiceProvider.overrideWithValue(FakeProfileService()),
        orderServiceProvider.overrideWithValue(orders),
      ],
    );
    // Keep the providers active, like the home screen does.
    container.listen(productsProvider, (previous, next) {});
    container.listen(priceBoundsProvider, (previous, next) {});
  });

  test('loads 6 books per page, newest first', () async {
    final page = await container.read(productsProvider.future);

    expect(productsPerPage, inInclusiveRange(6, 8));
    expect(page.products, hasLength(productsPerPage));
    expect(page.products.first.id, 20);
    expect(page.page, 1);
    expect(page.totalPages, 4); // 20 books / 6 per page
  });

  test('changing the page loads that page', () async {
    await container.read(productsProvider.future);

    container.read(currentPageProvider.notifier).goToPage(4);
    final page = await container.read(productsProvider.future);

    expect(service.pageRequests.last.page, 4);
    expect(page.products.map((book) => book.id), [2, 1]);
  });

  test('changing the filter goes back to page 1', () async {
    container.read(currentPageProvider.notifier).goToPage(3);
    expect(container.read(currentPageProvider), 3);

    container.read(productFilterProvider.notifier).setPriceRange(400, 450);

    expect(container.read(currentPageProvider), 1);
    final page = await container.read(productsProvider.future);
    expect(service.pageRequests.last.filter.minPrice, 400);
    expect(service.pageRequests.last.filter.maxPrice, 450);
    // Books 10 to 15 cost ₱400 to ₱450
    expect(page.totalCount, 6);
    expect(
      page.products.every((book) => book.price >= 400 && book.price <= 450),
      isTrue,
    );
  });

  test('picking a genre shows only that genre, from page 1', () async {
    expect(await container.read(genresProvider.future), sampleGenres);
    container.read(currentPageProvider.notifier).goToPage(3);

    container.read(productFilterProvider.notifier).setGenre(2); // Magic

    expect(container.read(currentPageProvider), 1);
    final page = await container.read(productsProvider.future);
    expect(service.pageRequests.last.filter.genreId, 2);
    expect(page.totalCount, 7);
    expect(page.totalPages, 2);
    expect(page.products.every((book) => book.genre == 'Magic'), isTrue);

    container.read(productFilterProvider.notifier).setGenre(null);
    final allBooks = await container.read(productsProvider.future);
    expect(allBooks.totalCount, 20);
  });

  test('setting the same filter again does not reload the books', () async {
    container.read(productFilterProvider.notifier).setPriceRange(400, 450);
    await container.read(productsProvider.future);
    final requestsBefore = service.pageRequests.length;

    container.read(productFilterProvider.notifier).setPriceRange(400, 450);
    await container.read(productsProvider.future);

    expect(service.pageRequests.length, requestsBefore);
  });

  test('adding a book goes to page 1 and shows it first', () async {
    container.read(currentPageProvider.notifier).goToPage(2);
    await container.read(productsProvider.future);

    final saved = await container
        .read(productActionsProvider)
        .addProduct(
          const Product(name: 'New Book', author: 'Someone', price: 999),
        );

    expect(container.read(currentPageProvider), 1);
    final page = await container.read(productsProvider.future);
    expect(page.products.first.id, saved.id);
    expect(page.totalCount, 21);
    // The price slider reloads too, so it now reaches ₱999
    final bounds = await container.read(priceBoundsProvider.future);
    expect(bounds!.max, 999);
  });

  test('deleting a book reloads the list', () async {
    final before = await container.read(productsProvider.future);

    await container
        .read(productActionsProvider)
        .deleteProduct(before.products.first);

    final after = await container.read(productsProvider.future);
    expect(after.totalCount, 19);
    expect(after.products.first.id, 19);
  });

  group('cart', () {
    late CartNotifier cart;
    setUp(() {
      container.listen(cartProvider, (previous, next) {});
      cart = container.read(cartProvider.notifier);
    });

    test('adds books, counts copies and keeps a running total', () {
      final books = service.books; // ₱310, ₱320, ...
      cart.add(books[0], quantity: 2);
      cart.add(books[1]);
      cart.add(books[0]); // same book: the quantity goes up

      expect(container.read(cartProvider), hasLength(2));
      expect(container.read(cartCountProvider), 4);
      expect(container.read(cartTotalProvider), 310 * 3 + 320);
    });

    test('refuses out-of-stock books and quantities above the stock', () {
      const soldOut = Product(id: 99, name: 'Gone', author: 'A', price: 1);
      expect(() => cart.add(soldOut), throwsA(isA<CartException>()));

      final book = service.books.first; // 5 in stock
      cart.add(book, quantity: 5);
      expect(() => cart.add(book), throwsA(isA<CartException>()));
      expect(() => cart.increment(book.id), throwsA(isA<CartException>()));
      expect(container.read(cartCountProvider), 5);
    });

    test('changing the quantity to 0 removes the book', () {
      final book = service.books.first;
      cart.add(book, quantity: 2);
      cart.decrement(book.id);
      expect(container.read(cartCountProvider), 1);
      cart.decrement(book.id);
      expect(container.read(cartProvider), isEmpty);
    });

    test('empties on logout', () async {
      container.listen(sessionProvider, (previous, next) {});
      cart.add(service.books.first);
      await auth.signOut();
      await Future<void>.delayed(Duration.zero);
      expect(container.read(cartProvider), isEmpty);
    });
  });

  group('checkout', () {
    setUp(() {
      container.listen(cartProvider, (previous, next) {});
    });

    test('sends only ids and quantities, then empties the cart', () async {
      final cart = container.read(cartProvider.notifier);
      cart.add(service.books[0], quantity: 2); // ₱310
      cart.add(service.books[1]); // ₱320

      final order = await container.read(orderActionsProvider).checkout();

      expect(orders.sentItems.single, [
        {'product_id': 1, 'quantity': 2},
        {'product_id': 2, 'quantity': 1},
      ]);
      expect(order.total, 310 * 2 + 320);
      expect(order.items.first.productName, 'Book 1');
      expect(container.read(cartProvider), isEmpty);
      expect(service.books[0].stock, 3);
      final history = await container.read(myOrdersProvider.future);
      expect(history.single.id, order.id);
    });

    test('a failed checkout keeps the cart and saves nothing', () async {
      final cart = container.read(cartProvider.notifier);
      cart.add(service.books[0], quantity: 2);
      service.books[0] = service.books[0].copyWith(stock: 1);

      await expectLater(
        container.read(orderActionsProvider).checkout(),
        throwsA(anything),
      );
      expect(container.read(cartCountProvider), 2);
      expect(orders.orders, isEmpty);
      expect(service.books[0].stock, 1);
    });

    test("an empty cart can't be checked out", () async {
      await expectLater(
        container.read(orderActionsProvider).checkout(),
        throwsA(isA<CartException>()),
      );
      expect(orders.sentItems, isEmpty);
    });
  });

  group('price slider scale', () {
    test('rounds the ends out to a tidy step', () {
      final scale = PriceSliderScale.fromBounds(
        const PriceBounds(min: 299, max: 699),
      );

      expect(scale.step, 10);
      expect(scale.lowest, 290);
      expect(scale.highest, 700);
      expect(scale.divisions, 41);
    });

    test('uses bigger steps for big price ranges', () {
      final scale = PriceSliderScale.fromBounds(
        const PriceBounds(min: 150, max: 9800),
      );

      expect(scale.step, 250);
      expect(scale.lowest, 0);
      expect(scale.highest, 10000);
      expect(scale.divisions, lessThanOrEqualTo(40));
    });

    test('still works when every book has the same price', () {
      final scale = PriceSliderScale.fromBounds(
        const PriceBounds(min: 500, max: 500),
      );

      expect(scale.highest, greaterThan(scale.lowest));
      expect(scale.divisions, greaterThan(0));
    });

    test('keeps both handles on the slider', () {
      final scale = PriceSliderScale.fromBounds(
        const PriceBounds(min: 299, max: 699),
      );

      // e.g. the filter was ₱720 - ₱800, then the priciest book was deleted
      final values = scale.clampValues(const RangeValues(720, 800));

      expect(values.start, 700);
      expect(values.end, 700);
    });
  });
}
