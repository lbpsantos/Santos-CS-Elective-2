import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_ui/main.dart';
import 'package:my_first_flutter_ui/models/cart.dart';
import 'package:my_first_flutter_ui/providers/auth_provider.dart';
import 'package:my_first_flutter_ui/providers/products_provider.dart';
import 'package:my_first_flutter_ui/routing/app_router.dart';
import 'package:my_first_flutter_ui/widgets/product_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session;

import 'fake_auth_service.dart';
import 'fake_product_service.dart';

// Tests for the login page, register page, route guard and account page.
void main() {
  Future<FakeAuthService> openApp(
    WidgetTester tester, {
    Session? session,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400); // 360 x 800 phone
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    clearCart();
    final auth = FakeAuthService(session);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(auth),
          productServiceProvider.overrideWithValue(
            FakeProductService(sampleBooks(20)),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();
    return auth;
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  testWidgets('logged-out users see the login page, not the shop', (
    tester,
  ) async {
    await openApp(tester);

    expect(find.text('Welcome back, Reader'), findsOneWidget);
    expect(find.text('Continue with GitHub'), findsOneWidget);
    expect(find.byType(ProductCard), findsNothing);
  });

  testWidgets('login checks the fields and shows a wrong password', (
    tester,
  ) async {
    await openApp(tester);
    final logInButton = find.widgetWithText(FilledButton, 'Log In');

    await tester.tap(logInButton);
    await tester.pumpAndSettle();
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);

    await tester.enterText(field('Email'), 'lucas@example.com');
    await tester.enterText(field('Password'), 'wrong-password');
    await tester.tap(logInButton);
    await tester.pumpAndSettle();
    expect(find.text('Wrong email or password.'), findsOneWidget);
    expect(find.byType(ProductCard), findsNothing);
  });

  testWidgets('logging in opens the shop', (tester) async {
    await openApp(tester);

    await tester.enterText(field('Email'), 'lucas@example.com');
    await tester.enterText(field('Password'), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Log In'));
    await tester.pumpAndSettle();

    expect(find.text('Hello, Lucas'), findsOneWidget);
    expect(find.byType(ProductCard), findsWidgets);
  });

  testWidgets('register checks the passwords, then logs the user in', (
    tester,
  ) async {
    final auth = await openApp(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Register'));
    await tester.pumpAndSettle();
    expect(find.text('Create an Account'), findsOneWidget);

    await tester.enterText(field('Full name'), 'Juan Dela Cruz');
    await tester.enterText(field('Email'), 'juan@example.com');
    await tester.enterText(field('Password'), 'secret123');
    await tester.enterText(field('Confirm password'), 'secret999');
    final createButton = find.widgetWithText(FilledButton, 'Create Account');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();
    expect(find.text('The passwords do not match'), findsOneWidget);

    await tester.enterText(field('Confirm password'), 'secret123');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(auth.accounts['juan@example.com'], 'secret123');
    expect(find.text('Hello, Juan'), findsOneWidget);
  });

  testWidgets('register asks to check the email when Supabase confirms it', (
    tester,
  ) async {
    final auth = await openApp(tester);
    auth.confirmEmail = true;
    await tester.tap(find.widgetWithText(TextButton, 'Register'));
    await tester.pumpAndSettle();

    await tester.enterText(field('Full name'), 'Juan Dela Cruz');
    await tester.enterText(field('Email'), 'juan@example.com');
    await tester.enterText(field('Password'), 'secret123');
    await tester.enterText(field('Confirm password'), 'secret123');
    final createButton = find.widgetWithText(FilledButton, 'Create Account');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(find.text('Check your email'), findsOneWidget);
    await tester.tap(find.text('Go to Log In'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back, Reader'), findsOneWidget);
  });

  testWidgets('registering a taken email shows an error', (tester) async {
    await openApp(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Register'));
    await tester.pumpAndSettle();

    await tester.enterText(field('Full name'), 'Lucas Santos');
    await tester.enterText(field('Email'), 'lucas@example.com');
    await tester.enterText(field('Password'), 'secret123');
    await tester.enterText(field('Confirm password'), 'secret123');
    final createButton = find.widgetWithText(FilledButton, 'Create Account');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(
      find.text('This email is already registered. Try logging in.'),
      findsOneWidget,
    );
  });

  testWidgets('the GitHub button starts the GitHub login', (tester) async {
    final auth = await openApp(tester);

    await tester.tap(find.text('Continue with GitHub'));
    await tester.pumpAndSettle();

    expect(auth.gitHubLogins, 1);
  });

  testWidgets('a failed GitHub login shows the reason', (tester) async {
    final auth = await openApp(tester);

    auth.failGitHubLogin('Unsupported provider: provider is not enabled');
    await tester.pumpAndSettle();

    expect(find.textContaining('GitHub login is not turned on'), findsOneWidget);
  });

  testWidgets('logged-in users who open /login go to the shop', (
    tester,
  ) async {
    await openApp(tester, session: fakeSession());
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MyApp)),
    );

    container.read(routerProvider).go(AppRoutes.login);
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, Reader'), findsNothing);
    expect(find.text('Hello, Lucas'), findsOneWidget);
  });

  testWidgets('the account page shows the user, but never the tokens', (
    tester,
  ) async {
    final session = fakeSession(provider: 'github', name: 'octocat');
    await openApp(tester, session: session);

    await tester.tap(find.byTooltip('My Account'));
    await tester.pumpAndSettle();

    expect(find.text('octocat'), findsOneWidget);
    expect(find.text('lucas@example.com'), findsOneWidget);
    expect(find.text('Logged in with GitHub'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
    // The access and refresh tokens stay private
    expect(find.textContaining(session.accessToken.substring(0, 10)), findsNothing);
    expect(find.textContaining('refresh-token'), findsNothing);
  });

  testWidgets('signing out goes to the login page and empties the cart', (
    tester,
  ) async {
    await openApp(tester, session: fakeSession());
    addToCart(sampleBooks(1).first, 2);

    await tester.tap(find.byTooltip('My Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, Reader'), findsOneWidget);
    expect(cartItems, isEmpty);
  });
}
