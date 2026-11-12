import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/cart_provider.dart';
import '../providers/theme_provider.dart';
import '../routing/app_router.dart';

// Light / dark mode button.
class ThemeToggleButton extends ConsumerWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return IconButton(
      tooltip: isDark ? 'Switch to Light' : 'Switch to Dark',
      icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode_outlined),
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
    );
  }
}

// The cart button with the number of books in the cart (customers only).
class CartButton extends ConsumerWidget {
  const CartButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartCountProvider);
    final colors = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: 'View Cart',
      onPressed: () => context.push(AppRoutes.cart),
      icon: Badge(
        isLabelVisible: count > 0,
        backgroundColor: colors.primary,
        textColor: colors.onPrimary,
        label: Text('$count'),
        child: const Icon(Icons.shopping_bag_outlined),
      ),
    );
  }
}
