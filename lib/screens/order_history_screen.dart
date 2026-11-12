import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/order_provider.dart';
import '../routing/app_router.dart';
import '../services/product_service.dart';
import '../widgets/order_widgets.dart';
import '../widgets/state_views.dart';

// The customer's own orders, newest first, with status, date, total and
// items. Supabase only sends this customer's orders (RLS).
class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: ordersAsync.when(
        loading: () => const LoadingView(message: 'Loading your orders...'),
        error: (error, _) => ErrorView(
          title: 'Could not load your orders',
          message: friendlyErrorMessage(error),
          onRetry: () => ref.invalidate(myOrdersProvider),
        ),
        data: (orders) => orders.isEmpty
            ? MessageView(
                icon: Icons.receipt_long_outlined,
                title: 'No orders yet',
                message: 'Your orders will show up here after you check out.',
                actionLabel: 'Browse Books',
                actionIcon: Icons.menu_book,
                onAction: () => context.go(AppRoutes.home),
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(myOrdersProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      OrderCard(order: orders[index]),
                ),
              ),
      ),
    );
  }
}
