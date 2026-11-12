import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/order.dart';
import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../screens/account_screen.dart';
import '../screens/admin_genres_screen.dart';
import '../screens/admin_orders_screen.dart';
import '../screens/cart_screen.dart';
import '../screens/checkout_confirmation_screen.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../screens/order_history_screen.dart';
import '../screens/product_detail_screen.dart';
import '../screens/product_form_screen.dart';
import '../screens/register_screen.dart';

// Route paths
abstract class AppRoutes {
  static const home = '/';
  static const productDetail = '/details';
  static const login = '/login';
  static const register = '/register';
  static const account = '/account';
  // Customers only
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const orders = '/orders';
  // Admins only
  static const productForm = '/admin/product';
  static const adminOrders = '/admin/orders';
  static const adminGenres = '/admin/genres';

  static const customerOnly = [cart, checkout, orders];
  static const adminOnly = [productForm, adminOrders, adminGenres];
}

// Router configuration. It is a provider so it can read the session and
// the user's role.
final routerProvider = Provider<GoRouter>((ref) {
  // GoRouter runs `redirect` again whenever this notifies, so logging in or
  // out, or the role loading, moves the user to the right page.
  final refresh = ValueNotifier<int>(0);
  ref.listen(sessionProvider, (previous, next) => refresh.value++);
  ref.listen(profileProvider, (previous, next) => refresh.value++);

  final router = GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refresh,
    // Route guard (auth gate + role gate). These guards only decide which
    // page is shown; Supabase's RLS policies are what protect the data.
    redirect: (context, state) {
      final loggedIn = ref.read(sessionProvider) != null;
      final location = state.matchedLocation;
      final onAuthPage =
          location == AppRoutes.login || location == AppRoutes.register;

      if (!loggedIn) return onAuthPage ? null : AppRoutes.login;
      if (onAuthPage) return AppRoutes.home;

      // Wait for the role before deciding about the role-only pages.
      final profile = ref.read(profileProvider);
      if (profile.isLoading && !profile.hasValue) return null;
      final isAdmin = profile.value?.isAdmin ?? false;

      if (AppRoutes.adminOnly.contains(location) && !isAdmin) {
        return AppRoutes.home;
      }
      if (AppRoutes.customerOnly.contains(location) && isAdmin) {
        return AppRoutes.home;
      }
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
        // The saved order is passed in `extra` after checkout.
        redirect: (context, state) =>
            state.extra is Order ? null : AppRoutes.home,
        builder: (context, state) =>
            CheckoutConfirmationScreen(order: state.extra! as Order),
      ),
      GoRoute(
        path: AppRoutes.orders,
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.productForm,
        // extra = the book to edit, or nothing to add a new book.
        builder: (context, state) =>
            ProductFormScreen(product: state.extra as Product?),
      ),
      GoRoute(
        path: AppRoutes.adminOrders,
        builder: (context, state) => const AdminOrdersScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminGenres,
        builder: (context, state) => const AdminGenresScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
