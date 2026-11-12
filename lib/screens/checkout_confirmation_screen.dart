import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/order.dart';
import '../routing/app_router.dart';
import '../widgets/order_widgets.dart';

// Shown after a successful checkout: the order number, the total and the
// items, exactly as Supabase saved them.
class CheckoutConfirmationScreen extends StatelessWidget {
  const CheckoutConfirmationScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Confirmed'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    size: 64,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Thank you for your order!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Order ${order.orderNumber}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Total paid: ₱${order.total.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                OrderCard(order: order, initiallyExpanded: true),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () => context.go(AppRoutes.home),
                    icon: const Icon(Icons.storefront_outlined),
                    label: const Text('Back to Store'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    context.go(AppRoutes.home);
                    context.push(AppRoutes.orders);
                  },
                  child: const Text('View My Orders'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
