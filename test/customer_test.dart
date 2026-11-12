import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_ui/models/product.dart';
import 'package:my_first_flutter_ui/providers/cart_provider.dart';
import 'package:my_first_flutter_ui/routing/app_router.dart';

import 'fake_auth_service.dart';
import 'fake_order_service.dart';
import 'fake_product_service.dart';
import 'test_app.dart';

// The customer's side: no admin controls, the cart, checkout and the
// order history.
void main() {
  // Three books: Book 3 (2 left), Book 2 (out of stock), Book 1 (5 left).
  FakeProductService smallShop() => FakeProductService([
    const Product(id: 1, name: 'Book 1', author: 'A', price: 100, stock: 5),
    const Product(id: 2, name: 'Book 2', author: 'B', price: 200, stock: 0),
    const Product(id: 3, name: 'Book 3', author: 'C', price: 300, stock: 2),
  ]);

  Future<TestShop> openAsCustomer(
    WidgetTester tester, {
    FakeProductService? products,
  }) {
    return openTestApp(tester, session: fakeSession(), products: products);
  }

  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  // The Add to Cart button on the card of [bookName].
  Finder addButtonOf(String bookName) => find.descendant(
    of: find.ancestor(of: find.text(bookName), matching: find.byType(Card)),
    matching: find.byType(FilledButton),
  );

  testWidgets('customers see Add to Cart, never the admin controls', (
    tester,
  ) async {
    await openAsCustomer(tester);

    expect(find.text('Add to Cart'), findsWidgets);
    expect(find.widgetWithText(FloatingActionButton, 'Add Book'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Edit'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'Delete'), findsNothing);
    expect(find.byTooltip('All Orders'), findsNothing);
    expect(find.byTooltip('View Cart'), findsOneWidget);
    expect(find.byTooltip('My Orders'), findsOneWidget);
  });

  testWidgets('out-of-stock books can\'t be added, and stock is a limit', (
    tester,
  ) async {
    final shop = await openAsCustomer(tester, products: smallShop());
    final cart = shop.container(tester);

    // Book 2 is sold out: its button is disabled
    final soldOut = tester.widget<FilledButton>(addButtonOf('Book 2'));
    expect(soldOut.onPressed, isNull);
    expect(find.text('Sold Out'), findsOneWidget);

    // Book 3 has 2 copies: the third one is refused
    await tapVisible(tester, addButtonOf('Book 3'));
    await tapVisible(tester, addButtonOf('Book 3'));
    expect(cart.read(cartCountProvider), 2);
    await tapVisible(tester, addButtonOf('Book 3'));
    expect(cart.read(cartCountProvider), 2);
    expect(find.textContaining('Only 2 copies of "Book 3"'), findsOneWidget);
  });

  testWidgets('the cart changes quantities, removes books and totals up', (
    tester,
  ) async {
    final shop = await openAsCustomer(tester, products: smallShop());
    final container = shop.container(tester);
    final books = shop.products.books;
    container.read(cartProvider.notifier).add(books[0]); // Book 1, ₱100
    container.read(cartProvider.notifier).add(books[2]); // Book 3, ₱300
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('View Cart'));
    await tester.pumpAndSettle();
    expect(find.text('Shopping Cart'), findsOneWidget);
    expect(find.text('2 books'), findsOneWidget);
    expect(find.text('₱400.00'), findsOneWidget);

    // Book 3: 1 -> 2 copies, then + is disabled (only 2 in stock)
    final plusButtons = find.byTooltip('Increase quantity');
    await tester.tap(plusButtons.last);
    await tester.pumpAndSettle();
    expect(find.text('3 books'), findsOneWidget);
    expect(find.text('₱700.00'), findsOneWidget);
    final plusForBook3 = tester.widget<IconButton>(
      find.ancestor(of: plusButtons.last, matching: find.byType(IconButton)),
    );
    expect(plusForBook3.onPressed, isNull);
    expect(find.text('Max 2 (all in stock)'), findsOneWidget);

    // Remove Book 1
    await tester.tap(find.byTooltip('Remove').first);
    await tester.pumpAndSettle();
    expect(find.text('Book 1'), findsNothing);
    expect(find.text('2 books'), findsOneWidget);
    expect(find.text('₱600.00'), findsWidgets);
  });

  testWidgets('the cart is kept when moving between screens', (tester) async {
    await openAsCustomer(tester, products: smallShop());

    await tapVisible(tester, addButtonOf('Book 1'));
    await tester.tap(find.byTooltip('View Cart'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('My Orders'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('View Cart'));
    await tester.pumpAndSettle();

    expect(find.text('Book 1'), findsOneWidget);
    expect(find.text('1 book'), findsOneWidget);
  });

  testWidgets('checkout saves the order, shows it, and empties the cart', (
    tester,
  ) async {
    final shop = await openAsCustomer(tester, products: smallShop());
    final container = shop.container(tester);
    final books = shop.products.books;
    container.read(cartProvider.notifier).add(books[0], quantity: 2);
    container.read(cartProvider.notifier).add(books[2]);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('View Cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();

    // Only ids and quantities were sent; prices come from the "database"
    expect(shop.orders.sentItems.single, [
      {'product_id': 1, 'quantity': 2},
      {'product_id': 3, 'quantity': 1},
    ]);
    // Confirmation with the order number and total
    expect(find.text('Thank you for your order!'), findsOneWidget);
    expect(find.text('Order #00001'), findsWidgets);
    expect(find.text('Total paid: ₱500.00'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    // The cart is empty and the stock went down
    expect(container.read(cartProvider), isEmpty);
    expect(shop.products.books[0].stock, 3);
    expect(shop.products.books[2].stock, 1);

    // The order history lists it
    await tester.tap(find.text('View My Orders'));
    await tester.pumpAndSettle();
    expect(find.text('My Orders'), findsOneWidget);
    expect(find.text('Order #00001'), findsOneWidget);
    expect(find.text('3 books · ₱500.00'), findsOneWidget);
  });

  testWidgets('a failed checkout saves nothing and keeps the cart', (
    tester,
  ) async {
    final shop = await openAsCustomer(tester, products: smallShop());
    final container = shop.container(tester);
    container.read(cartProvider.notifier).add(shop.products.books[2], quantity: 2);
    // Someone else bought a copy in the meantime
    shop.products.books[2] = shop.products.books[2].copyWith(stock: 1);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('View Cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();

    expect(find.text('Order not placed'), findsOneWidget);
    expect(find.textContaining('Only 1 left in stock for "Book 3"'), findsOne);
    expect(shop.orders.orders, isEmpty);
    expect(container.read(cartCountProvider), 2);
  });

  testWidgets('order history lists newest first, and is empty at first', (
    tester,
  ) async {
    final products = smallShop();
    final shop = await openAsCustomer(tester, products: products);
    await tester.tap(find.byTooltip('My Orders'));
    await tester.pumpAndSettle();
    expect(find.text('No orders yet'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Two orders made earlier
    final orders = FakeOrderService(products);
    await orders.placeOrder([{'product_id': 1, 'quantity': 1}]);
    await orders.placeOrder([{'product_id': 3, 'quantity': 1}]);
    shop.orders.orders.addAll(orders.orders);
    await tester.tap(find.byTooltip('My Orders'));
    await tester.pumpAndSettle();

    final first = tester.getTopLeft(find.text('Order #00002'));
    final second = tester.getTopLeft(find.text('Order #00001'));
    expect(first.dy, lessThan(second.dy));
  });

  testWidgets('a checkout error from Supabase is shown, not swallowed', (
    tester,
  ) async {
    final shop = await openAsCustomer(tester, products: smallShop());
    final container = shop.container(tester);
    container.read(cartProvider.notifier).add(shop.products.books[0]);
    // The book was deleted by an admin
    shop.products.books.removeAt(0);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('View Cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Checkout'));
    await tester.pumpAndSettle();

    expect(find.text('A book in your cart is no longer available.\n\n'
        'Nothing was saved and your cart was not changed.'), findsOneWidget);
  });

  testWidgets('customers can\'t open admin pages', (tester) async {
    final shop = await openAsCustomer(tester);
    final router = shop.container(tester).read(routerProvider);

    for (final page in AppRoutes.adminOnly) {
      router.go(page);
      await tester.pumpAndSettle();
      expect(find.text('Hello, Lucas'), findsOneWidget, reason: page);
    }
  });

  testWidgets('admins can\'t open the cart or place orders', (tester) async {
    final shop = await openTestApp(
      tester,
      session: fakeSession(),
      role: 'admin',
    );
    final router = shop.container(tester).read(routerProvider);

    router.go(AppRoutes.cart);
    await tester.pumpAndSettle();
    expect(find.text('Shopping Cart'), findsNothing);
    expect(find.text('Hello, Lucas'), findsOneWidget);
  });
}
