import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_flutter_ui/main.dart';
import 'package:my_first_flutter_ui/providers/auth_provider.dart';
import 'package:my_first_flutter_ui/providers/order_provider.dart';
import 'package:my_first_flutter_ui/providers/products_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Session;

import 'fake_auth_service.dart';
import 'fake_order_service.dart';
import 'fake_product_service.dart';
import 'fake_profile_service.dart';
import 'fake_storage_service.dart';

// The app with fake services instead of Supabase, for the widget tests.
class TestShop {
  TestShop({
    required this.auth,
    required this.products,
    required this.profiles,
    required this.orders,
    required this.storage,
  });

  final FakeAuthService auth;
  final FakeProductService products;
  final FakeProfileService profiles;
  final FakeOrderService orders;
  final FakeStorageService storage;

  ProviderContainer container(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MyApp)));
}

// A phone-sized screen (360 x 800), so the 2-column layout is used.
void usePhoneScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

// Opens the app. Pass a [session] to start logged in, and a [role]
// ("customer" or "admin") for that user's profile.
Future<TestShop> openTestApp(
  WidgetTester tester, {
  Session? session,
  String role = 'customer',
  FakeProductService? products,
  bool phone = true,
}) async {
  if (phone) usePhoneScreen(tester);
  final productService = products ?? FakeProductService(sampleBooks(20));
  final shop = TestShop(
    auth: FakeAuthService(session),
    products: productService,
    profiles: FakeProfileService(role: role),
    orders: FakeOrderService(productService),
    storage: FakeStorageService(),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(shop.auth),
        productServiceProvider.overrideWithValue(shop.products),
        profileServiceProvider.overrideWithValue(shop.profiles),
        orderServiceProvider.overrideWithValue(shop.orders),
        storageServiceProvider.overrideWithValue(shop.storage),
      ],
      child: const MyApp(),
    ),
  );
  await tester.pumpAndSettle();
  return shop;
}
