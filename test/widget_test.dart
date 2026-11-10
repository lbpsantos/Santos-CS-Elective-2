import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_ui/main.dart';
import 'package:my_first_flutter_ui/models/cart.dart';
import 'package:my_first_flutter_ui/providers/auth_provider.dart';
import 'package:my_first_flutter_ui/providers/products_provider.dart';
import 'package:my_first_flutter_ui/responsive/tablet_scaffold.dart';
import 'package:my_first_flutter_ui/widgets/product_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'fake_auth_service.dart';
import 'fake_product_service.dart';

// Tests that use the real screens, with fake books instead of Supabase.
// The user is already logged in (the login pages are tested in auth_test).
void main() {
  // A phone-sized screen (360 x 800), so the 2-column layout is used.
  void usePhoneScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  Future<FakeProductService> openShop(
    WidgetTester tester, {
    FakeProductService? service,
  }) async {
    clearCart();
    final fakeService = service ?? FakeProductService(sampleBooks(20));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productServiceProvider.overrideWithValue(fakeService),
          authServiceProvider.overrideWithValue(FakeAuthService(fakeSession())),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    return fakeService;
  }

  testWidgets('shows the first 6 books, the price slider and page buttons', (
    tester,
  ) async {
    usePhoneScreen(tester);
    await openShop(tester);

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
    usePhoneScreen(tester);
    final service = await openShop(tester);

    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();

    expect(service.pageRequests.last.page, 2);
    expect(find.text('Showing 7–12 of 20 books'), findsOneWidget);
    expect(find.text('Book 14'), findsOneWidget);
    expect(find.text('Book 20'), findsNothing);
  });

  testWidgets('dragging the price slider filters the books', (tester) async {
    usePhoneScreen(tester);
    final service = await openShop(tester);
    await tester.tap(find.byTooltip('Next page'));
    await tester.pumpAndSettle();

    // Drag the left (lowest price) handle to the right
    final slider = find.byType(RangeSlider);
    await tester.dragFrom(
      tester.getRect(slider).centerLeft + const Offset(24, 0),
      const Offset(150, 0),
    );
    await tester.pumpAndSettle();

    final request = service.pageRequests.last;
    expect(request.page, 1); // a new filter starts on page 1
    expect(request.filter.minPrice, isNotNull);
    expect(request.filter.maxPrice, isNull); // right handle not moved
    final shownPrices = tester
        .widgetList<ProductCard>(find.byType(ProductCard))
        .map((card) => card.product.price);
    expect(shownPrices, isNotEmpty);
    expect(shownPrices.every((price) => price >= request.filter.minPrice!), isTrue);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(service.pageRequests.last.filter.hasPriceRange, isFalse);
    expect(find.text('Showing 1–6 of 20 books'), findsOneWidget);
  });

  testWidgets('the genre dropdown filters the books', (tester) async {
    usePhoneScreen(tester);
    final service = await openShop(tester);

    await tester.tap(find.text('All genres'));
    await tester.pumpAndSettle();
    // .last = the item in the opened menu
    await tester.tap(find.text('Magic').last);
    await tester.pumpAndSettle();

    expect(service.pageRequests.last.filter.genreId, 2);
    expect(find.text('Showing 1–6 of 7 books'), findsOneWidget);
    final shownGenres = tester
        .widgetList<ProductCard>(find.byType(ProductCard))
        .map((card) => card.product.genre);
    expect(shownGenres, everyElement('Magic'));

    // Clear filters also resets the genre
    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(service.pageRequests.last.filter.genreId, isNull);
    expect(find.text('All genres'), findsOneWidget);
  });

  testWidgets('Add Book checks the form, then saves the book', (tester) async {
    usePhoneScreen(tester);
    final service = await openShop(tester);

    await tester.tap(find.text('Add Book'));
    await tester.pumpAndSettle();

    final saveButton = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text('Add Book'),
    );
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(find.text('Enter the title'), findsOneWidget);
    expect(find.text('Enter the author'), findsOneWidget);
    expect(find.text('Enter a price, e.g. 499'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Title'),
      'The Hobbit',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Author'),
      'J.R.R. Tolkien',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price (₱)'),
      '399',
    );
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

    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Added "The Hobbit"'), findsOneWidget);
    final hobbit = service.books.singleWhere(
      (book) => book.name == 'The Hobbit',
    );
    expect(hobbit.price, 399);
    expect(hobbit.genreId, 3);
    expect(hobbit.genre, 'Mystery');
    // New books are listed first
    expect(find.text('The Hobbit'), findsOneWidget);
    expect(find.text('Showing 1–6 of 21 books'), findsOneWidget);
  });

  testWidgets('a book can be deleted from its card menu', (tester) async {
    usePhoneScreen(tester);
    final service = await openShop(tester);

    // The first card is the newest book, Book 20
    await tester.tap(find.byTooltip('Edit or delete').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete Book?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(service.books.any((book) => book.id == 20), isFalse);
    expect(find.text('Deleted "Book 20"'), findsOneWidget);
    expect(find.text('Showing 1–6 of 19 books'), findsOneWidget);
  });

  testWidgets('a book can be edited from its details page', (tester) async {
    usePhoneScreen(tester);
    final service = await openShop(tester);

    await tester.tap(find.byType(ProductCard).first);
    await tester.pumpAndSettle();
    expect(find.text('Book Details'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit or delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Price (₱)'),
      '777',
    );
    final saveButton = find.text('Save Changes');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(service.books.singleWhere((book) => book.id == 20).price, 777);
    // The details page shows the saved price right away
    expect(find.text('₱777.00'), findsOneWidget);
  });

  testWidgets('a missing table shows a helpful message and Retry', (
    tester,
  ) async {
    usePhoneScreen(tester);
    final service = FakeProductService(sampleBooks(3))
      ..errorToThrow = const PostgrestException(
        message: "Could not find the table 'public.products'",
        code: 'PGRST205',
      );
    await openShop(tester, service: service);

    expect(find.text('Could not load the books'), findsOneWidget);
    expect(find.textContaining('supabase/products.sql'), findsOneWidget);
    expect(find.byTooltip('Next page'), findsNothing);

    service.errorToThrow = null;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductCard), findsNWidgets(3));
  });

  testWidgets('tablets show the 3-column grid', (tester) async {
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await openShop(tester);

    expect(find.byType(TabletScaffold), findsOneWidget);
    expect(find.byType(ProductCard), findsNWidgets(6));
  });
}
