import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_ui/models/order.dart';

import 'fake_auth_service.dart';
import 'test_app.dart';

// The admin's order list and genre (category) manager.
void main() {
  Future<TestShop> openAsAdmin(WidgetTester tester) {
    return openTestApp(tester, session: fakeSession(), role: 'admin');
  }

  testWidgets('the admin order list shows every order and changes status', (
    tester,
  ) async {
    final shop = await openAsAdmin(tester);
    await shop.orders.placeOrder([
      {'product_id': 1, 'quantity': 2},
    ]);

    await tester.tap(find.byTooltip('All Orders'));
    await tester.pumpAndSettle();
    expect(find.text('All Orders'), findsOneWidget);
    expect(find.text('Order #00001'), findsOneWidget);
    expect(find.textContaining('Lucas Santos'), findsOneWidget);

    // Open the order and set it back to pending
    await tester.tap(find.text('Order #00001'));
    await tester.pumpAndSettle();
    expect(find.text('Book 1'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<OrderStatus>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pending').last);
    await tester.pumpAndSettle();

    expect(shop.orders.orders.single.status, OrderStatus.pending);
    expect(find.text('Order #00001 is now Pending'), findsOneWidget);
  });

  testWidgets('the admin order list says when there are no orders', (
    tester,
  ) async {
    await openAsAdmin(tester);

    await tester.tap(find.byTooltip('All Orders'));
    await tester.pumpAndSettle();

    expect(find.text('No orders yet'), findsOneWidget);
  });

  testWidgets('admins add, rename and delete genres', (tester) async {
    final shop = await openAsAdmin(tester);
    await tester.tap(find.byTooltip('Manage Genres'));
    await tester.pumpAndSettle();
    expect(find.text('Adventure'), findsOneWidget);

    // Add
    await tester.tap(find.text('Add Genre'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Sci-Fi');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(shop.products.genres.map((genre) => genre.name), contains('Sci-Fi'));
    expect(find.text('Sci-Fi'), findsOneWidget);

    // Rename
    await tester.tap(find.byTooltip('Rename').first); // Adventure
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Quest');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Quest'), findsOneWidget);
    expect(find.text('Adventure'), findsNothing);

    // Delete asks first
    await tester.tap(find.byTooltip('Delete').first);
    await tester.pumpAndSettle();
    expect(find.text('Delete "Magic"?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(shop.products.genres.any((genre) => genre.name == 'Magic'), isFalse);
    // Magic's books are kept, with no genre
    expect(shop.products.books.where((book) => book.genreId == 2), isEmpty);
    expect(shop.products.books, hasLength(20));
  });
}
