import 'package:go_router/go_router.dart';

import '../models/product.dart';
import '../screens/cart_screen.dart';
import '../screens/checkout_confirmation_screen.dart';
import '../screens/home_screen.dart';
import '../screens/product_detail_screen.dart';

// Route paths
abstract class AppRoutes {
  static const home = '/';
  static const productDetail = '/details';
  static const cart = '/cart';
  static const checkout = '/checkout';
}

// Router configuration
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
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
