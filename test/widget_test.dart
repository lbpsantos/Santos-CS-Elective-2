import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_ui/responsive/tablet_scaffold.dart';
import 'package:my_first_flutter_ui/widgets/product_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'fake_auth_service.dart';
import 'fake_product_service.dart';
import 'test_app.dart';

// The shop's product list: browsing, filtering and pages (both roles), and
// the admin's add / edit / delete. Customer cart and checkout tests are in
// customer_test.dart.
void main() {
  Future<TestShop> openAsAdmin(
    WidgetTester tester, {
    FakeProductService? products,
  }) {
    return openTestApp(
      tester,
      session: fakeSession(),
      role: 'admin',
      products: products,
    );
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  // Scrolls to a widget first, so the tap lands on it.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('shows the first 6 books, the price slider and page buttons', (
    tester,
  ) async {
    await openTestApp(tester, session: fakeSession());

    expect(find.byType(ProductCard), findsNWidgets(6));
    expect(find.text('Showing 1–6 of 20 books'), findsOneWidget);
    for (final pageNumber in ['1', '2', '3', '4']) {
      expect(find.text(pageNumber), findsOneWidget);
    }
    expect(find.byType(RangeSlider), findsOneWidget);
    // The fake books cost ₱310 to ₱500
    expect(find.text('₱310 – ₱500'), findsOneWidget);
  });

  testWidgets('the Next button shows page 2', (tester) async {
    final shop = await openTestApp(tester, session: fakeSession());

    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();

    expect(shop.products.pageRequests.last.page, 2);
    expect(find.text('Showing 7–12 of 20 books'), findsOneWidget);
    expect(find.text('Book 14'), findsOneWidget);
    expect(find.text('Book 20'), findsNothing);
  });

  testWidgets('dragging the price slider filters the books', (tester) async {
    final shop = await openTestApp(tester, session: fakeSession());
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();

    // Drag the left (lowest price) handle to the right
    final slider = find.byType(RangeSlider);
    await tester.dragFrom(
      tester.getRect(slider).centerLeft + const Offset(24, 0),
      const Offset(150, 0),
    );
    await tester.pumpAndSettle();

    final request = shop.products.pageRequests.last;
    expect(request.page, 1); // a new filter starts on page 1
    expect(request.filter.minPrice, isNotNull);
    expect(request.filter.maxPrice, isNull); // right handle not moved
    final shownPrices = tester
        .widgetList<ProductCard>(find.byType(ProductCard))
        .map((card) => card.product.price);
    expect(shownPrices, isNotEmpty);
    expect(
      shownPrices.every((price) => price >= request.filter.minPrice!),
      isTrue,
    );

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(shop.products.pageRequests.last.filter.hasPriceRange, isFalse);
    expect(find.text('Showing 1–6 of 20 books'), findsOneWidget);
  });

  testWidgets('the genre dropdown filters the books', (tester) async {
    final shop = await openTestApp(tester, session: fakeSession());

    await tester.tap(find.text('All genres'));
    await tester.pumpAndSettle();
    // .last = the item in the opened menu
    await tester.tap(find.text('Magic').last);
    await tester.pumpAndSettle();

    expect(shop.products.pageRequests.last.filter.genreId, 2);
    expect(find.text('Showing 1–6 of 7 books'), findsOneWidget);
    final shownGenres = tester
        .widgetList<ProductCard>(find.byType(ProductCard))
        .map((card) => card.product.genre);
    expect(shownGenres, everyElement('Magic'));

    // Clear filters also resets the genre
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(shop.products.pageRequests.last.filter.genreId, isNull);
    expect(find.text('All genres'), findsOneWidget);
  });

  testWidgets('admins see the Add Book button and Edit / Delete on cards', (
    tester,
  ) async {
    await openAsAdmin(tester);

    expect(find.widgetWithText(FloatingActionButton, 'Add Book'), findsOne);
    expect(find.widgetWithText(OutlinedButton, 'Edit'), findsNWidgets(6));
    expect(find.widgetWithText(OutlinedButton, 'Delete'), findsNWidgets(6));
    expect(find.text('Add to Cart'), findsNothing);
    expect(find.byTooltip('View Cart'), findsNothing);
    expect(find.byTooltip('All Orders'), findsOneWidget);
  });

  testWidgets('the Add Book page checks the form, then saves the book', (
    tester,
  ) async {
    final shop = await openAsAdmin(tester);

    await tester.tap(find.text('Add Book'));
    await tester.pumpAndSettle();
    expect(find.text('Add a Book'), findsOneWidget);

    final saveButton = find.widgetWithText(FilledButton, 'Add Book');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(find.text('Enter the title'), findsOneWidget);
    expect(find.text('Enter a price, e.g. 499'), findsOneWidget);
    expect(find.text('Enter the stock, e.g. 10'), findsOneWidget);

    await tester.enterText(field('Title'), 'The Hobbit');
    await tester.enterText(field('Author'), 'J.R.R. Tolkien');
    // Price must be 0 or more, stock a whole number of 0 or more
    await tester.enterText(field('Price (₱)'), '-5');
    await tester.enterText(field('Stock'), '2.5');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(find.text('The price can\'t be below 0'), findsOneWidget);
    expect(find.text('Use a whole number'), findsOneWidget);

    await tester.enterText(field('Price (₱)'), '0');
    await tester.enterText(field('Stock'), '12');
    // Pick a genre from the genres table
    final genreField = find.text('No genre');
    await tester.ensureVisible(genreField);
    await tester.tap(genreField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mystery').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Add a Book'), findsNothing); // back on the shop
    expect(find.text('Added "The Hobbit"'), findsOneWidget);
    final hobbit = shop.products.books.singleWhere(
      (book) => book.name == 'The Hobbit',
    );
    expect(hobbit.price, 0);
    expect(hobbit.stock, 12);
    expect(hobbit.genre, 'Mystery');
    // New books are listed first
    expect(find.text('The Hobbit'), findsOneWidget);
    expect(find.text('Showing 1–6 of 21 books'), findsOneWidget);
  });

  testWidgets('deleting asks first, naming the book', (tester) async {
    final shop = await openAsAdmin(tester);

    // The first card is the newest book, Book 20
    await tapVisible(tester, find.widgetWithText(OutlinedButton, 'Delete').first);
    expect(find.text('Delete "Book 20"?'), findsOneWidget);

    // Cancel keeps the book
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(shop.products.books.any((book) => book.id == 20), isTrue);

    await tapVisible(tester, find.widgetWithText(OutlinedButton, 'Delete').first);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(shop.products.books.any((book) => book.id == 20), isFalse);
    expect(find.text('Deleted "Book 20"'), findsOneWidget);
    expect(find.text('Showing 1–6 of 19 books'), findsOneWidget);
  });

  testWidgets('the edit form starts filled in and saves the changes', (
    tester,
  ) async {
    final shop = await openAsAdmin(tester);

    await tapVisible(tester, find.widgetWithText(OutlinedButton, 'Edit').first);
    expect(find.text('Edit Book'), findsOneWidget);
    // The form starts with Book 20's values
    expect(find.widgetWithText(TextFormField, 'Book 20'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '500.00'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '5'), findsOneWidget);

    await tester.enterText(field('Price (₱)'), '777');
    await tester.enterText(field('Stock'), '0');
    final saveButton = find.text('Save Changes');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    final saved = shop.products.books.singleWhere((book) => book.id == 20);
    expect(saved.price, 777);
    expect(saved.stock, 0);
    expect(find.text('₱777.00'), findsOneWidget);
    expect(find.text('Out of stock'), findsOneWidget);
  });

  testWidgets('a book can be edited from its details page', (tester) async {
    final shop = await openAsAdmin(tester);

    await tapVisible(tester, find.text('Book 20'));
    expect(find.text('Book Details'), findsOneWidget);
    // Admins don't get the quantity picker
    expect(find.textContaining('Add to Cart'), findsNothing);

    await tester.tap(find.byTooltip('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(field('Price (₱)'), '777');
    final saveButton = find.text('Save Changes');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(shop.products.books.singleWhere((book) => book.id == 20).price, 777);
    // The details page shows the saved price right away
    expect(find.text('Book Details'), findsOneWidget);
    expect(find.text('₱777.00'), findsOneWidget);
  });

  testWidgets('a missing table shows a helpful message and Retry', (
    tester,
  ) async {
    final products = FakeProductService(sampleBooks(3))
      ..errorToThrow = const PostgrestException(
        message: "Could not find the table 'public.products'",
        code: 'PGRST205',
      );
    await openTestApp(tester, session: fakeSession(), products: products);

    expect(find.text('Could not load the books'), findsOneWidget);
    expect(find.textContaining('supabase/products.sql'), findsOneWidget);
    expect(find.byTooltip('Next page'), findsNothing);

    products.errorToThrow = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductCard), findsNWidgets(3));
  });

  testWidgets('a permission error says so instead of failing silently', (
    tester,
  ) async {
    final products = FakeProductService(sampleBooks(3))
      ..errorToThrow = const PostgrestException(
        message: 'permission denied for table products',
        code: '42501',
      );
    await openTestApp(tester, session: fakeSession(), products: products);

    expect(find.textContaining('Permission denied'), findsOneWidget);
  });

  testWidgets('tablets show the 3-column grid', (tester) async {
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await openTestApp(tester, session: fakeSession(), phone: false);

    expect(find.byType(TabletScaffold), findsOneWidget);
    expect(find.byType(ProductCard), findsNWidgets(6));
  });
}
