import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../screens/account_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/checkout_confirmation_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/register_screen.dart';

// Route paths
abstract class AppRoutes {
  static const home = '/';
  static const productDetail = '/details';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const login = '/login';
  static const register = '/register';
  static const account = '/account';
}

// Router configuration. It is a provider so it can read the session.
final routerProvider = Provider<GoRouter>((ref) {
  // true when logged in. GoRouter runs `redirect` again whenever this
  // changes, so logging in or out moves the user to the right page.
  final loggedIn = ValueNotifier<bool>(ref.read(sessionProvider) != null);
  ref.listen(sessionProvider, (previous, session) {
    loggedIn.value = session != null;
  });

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: loggedIn,
    // Route guard: the shop is only for logged-in users.
    redirect: (context, state) {
      final onAuthPage =
          state.matchedLocation == AppRoutes.login ||
          state.matchedLocation == AppRoutes.register;
      if (!loggedIn.value && !onAuthPage) return AppRoutes.login;
      if (loggedIn.value && onAuthPage) return AppRoutes.home;
      return null; // stay on the page
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.account,
        builder: (context, state) => const AccountScreen(),
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        // The book is passed in `extra`. It is missing when the page is opened
        // directly (e.g. reloading /details on the web), so go back home.
        redirect: (context, state) =>
            state.extra is Product ? null : AppRoutes.home,
        builder: (context, state) =>
            ProductDetailScreen(product: state.extra! as Product),
      ),
      GoRoute(
        path: AppRoutes.cart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        builder: (context, state) => const CheckoutConfirmationScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    loggedIn.dispose();
  });
  return router;
});
