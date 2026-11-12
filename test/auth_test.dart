import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_ui/providers/auth_provider.dart';
import 'package:my_first_flutter_ui/providers/cart_provider.dart';
import 'package:my_first_flutter_ui/routing/app_router.dart';
import 'package:my_first_flutter_ui/widgets/product_card.dart';

import 'fake_auth_service.dart';
import 'fake_product_service.dart';
import 'test_app.dart';

// Tests for the login page, register page, auth gate and account page.
void main() {
  Finder field(String label) => find.widgetWithText(TextFormField, label);

  testWidgets('logged-out users see the login page, not the shop', (
    tester,
  ) async {
    await openTestApp(tester);

    expect(find.text('Welcome back, Reader'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.byType(ProductCard), findsNothing);
  });

  testWidgets('login checks the fields and shows a wrong password', (
    tester,
  ) async {
    await openTestApp(tester);
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

  testWidgets('logging in loads the profile and opens the shop', (
    tester,
  ) async {
    final shop = await openTestApp(tester);

    await tester.enterText(field('Email'), 'lucas@example.com');
    await tester.enterText(field('Password'), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Log In'));
    await tester.pumpAndSettle();

    expect(shop.profiles.loads, 1);
    expect(find.text('Hello, Lucas'), findsOneWidget);
    expect(find.byType(ProductCard), findsWidgets);
  });

  testWidgets('register asks for first and last name, then logs in', (
    tester,
  ) async {
    final shop = await openTestApp(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Register'));
    await tester.pumpAndSettle();
    expect(find.text('Create an Account'), findsOneWidget);

    final createButton = find.widgetWithText(FilledButton, 'Create Account');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();
    expect(find.text('Enter your first name'), findsOneWidget);
    expect(find.text('Enter your last name'), findsOneWidget);

    await tester.enterText(field('First name'), 'Juan');
    await tester.enterText(field('Last name'), 'Dela Cruz');
    await tester.enterText(field('Email'), 'juan@example.com');
    await tester.enterText(field('Password'), 'secret123');
    await tester.enterText(field('Confirm password'), 'secret999');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();
    expect(find.text('The passwords do not match'), findsOneWidget);

    await tester.enterText(field('Confirm password'), 'secret123');
    await tester.ensureVisible(createButton);
    await tester.tap(createButton);
    await tester.pumpAndSettle();

    expect(shop.auth.accounts['juan@example.com'], 'secret123');
    expect(find.text('Hello, Juan'), findsOneWidget);
  });

  testWidgets('register asks to check the email when Supabase confirms it', (
    tester,
  ) async {
    final shop = await openTestApp(tester);
    shop.auth.confirmEmail = true;
    await tester.tap(find.widgetWithText(TextButton, 'Register'));
    await tester.pumpAndSettle();

    await tester.enterText(field('First name'), 'Juan');
    await tester.enterText(field('Last name'), 'Dela Cruz');
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
    await openTestApp(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Register'));
    await tester.pumpAndSettle();

    await tester.enterText(field('First name'), 'Lucas');
    await tester.enterText(field('Last name'), 'Santos');
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

  testWidgets('the Google button starts the Google login', (tester) async {
    final shop = await openTestApp(tester);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(shop.auth.googleLogins, 1);
  });

  testWidgets('a failed Google login shows the reason', (tester) async {
    final shop = await openTestApp(tester);

    shop.auth.failGoogleLogin('Unsupported provider: provider is not enabled');
    await tester.pumpAndSettle();

    expect(
      find.textContaining('login provider is not turned on'),
      findsOneWidget,
    );
  });

  testWidgets('logged-in users who open /login go to the shop', (
    tester,
  ) async {
    final shop = await openTestApp(tester, session: fakeSession());

    shop.container(tester).read(routerProvider).go(AppRoutes.login);
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, Reader'), findsNothing);
    expect(find.text('Hello, Lucas'), findsOneWidget);
  });

  testWidgets('a missing profile row shows how to fix it', (tester) async {
    final shop = await openTestApp(tester, session: fakeSession());
    shop.profiles.missing = true;

    shop.container(tester).invalidate(profileProvider);
    await tester.pumpAndSettle();

    expect(find.text('Profile not found'), findsOneWidget);
    expect(find.textContaining('final_project.sql'), findsOneWidget);
  });

  testWidgets('the account page shows the profile and role, not tokens', (
    tester,
  ) async {
    final session = fakeSession(provider: 'google', name: 'Lucas Santos');
    await openTestApp(tester, session: session);

    await tester.tap(find.byTooltip('My Account'));
    await tester.pumpAndSettle();

    expect(find.text('Lucas Santos'), findsOneWidget);
    expect(find.text('lucas@example.com'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Logged in with Google'), findsOneWidget);
    expect(find.text('Sign Out'), findsOneWidget);
    // The access and refresh tokens stay private
    expect(
      find.textContaining(session.accessToken.substring(0, 10)),
      findsNothing,
    );
    expect(find.textContaining('refresh-token'), findsNothing);
  });

  testWidgets('a user can change their own name', (tester) async {
    final shop = await openTestApp(tester, session: fakeSession());
    await tester.tap(find.byTooltip('My Account'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit name'));
    await tester.pumpAndSettle();
    await tester.enterText(field('First name'), 'Luke');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(shop.profiles.firstName, 'Luke');
    expect(find.text('Luke Santos'), findsOneWidget);
  });

  testWidgets('signing out goes to the login page and empties the cart', (
    tester,
  ) async {
    final shop = await openTestApp(tester, session: fakeSession());
    final container = shop.container(tester);
    container.read(cartProvider.notifier).add(sampleBooks(1).first, quantity: 2);
    expect(container.read(cartCountProvider), 2);

    await tester.tap(find.byTooltip('My Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign Out'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back, Reader'), findsOneWidget);
    expect(container.read(cartProvider), isEmpty);
  });
}
