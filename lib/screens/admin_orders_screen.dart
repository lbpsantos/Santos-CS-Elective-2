import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../providers/auth_provider.dart';
import '../providers/order_provider.dart';
import '../services/product_service.dart';
import '../widgets/order_widgets.dart';
import '../widgets/state_views.dart';

// Every customer's orders, newest first (admins only). The admin can
// change an order's status.
class AdminOrdersScreen extends ConsumerWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isAdminProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('All Orders')),
        body: const NoAccessView(message: 'Only admins can see all orders.'),
      );
    }

    final ordersAsync = ref.watch(allOrdersProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('All Orders')),
      body: ordersAsync.when(
        loading: () => const LoadingView(message: 'Loading orders...'),
        error: (error, _) => ErrorView(
          title: 'Could not load the orders',
          message: friendlyErrorMessage(error),
          onRetry: () => ref.invalidate(allOrdersProvider),
        ),
        data: (orders) => orders.isEmpty
            ? const MessageView(
                icon: Icons.receipt_long_outlined,
                title: 'No orders yet',
                message: 'Customer orders will show up here.',
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(allOrdersProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) return _Summary(orders: orders);
                    final order = orders[index - 1];
                    return OrderCard(
                      order: order,
                      showCustomer: true,
                      statusControl: _StatusPicker(order: order),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

// "12 orders · ₱8,450.00 in sales"
class _Summary extends StatelessWidget {
  const _Summary({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final sales = orders
        .where((order) => order.status == OrderStatus.done)
        .fold(0.0, (sum, order) => sum + order.total);
    final theme = Theme.of(context);
    return Text(
      '${orders.length} ${orders.length == 1 ? 'order' : 'orders'} · '
      '₱${sales.toStringAsFixed(2)} in completed sales',
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// The status dropdown at the bottom of an opened order.
class _StatusPicker extends ConsumerStatefulWidget {
  const _StatusPicker({required this.order});

  final Order order;

  @override
  ConsumerState<_StatusPicker> createState() => _StatusPickerState();
}

class _StatusPickerState extends ConsumerState<_StatusPicker> {
  bool _saving = false;

  Future<void> _change(OrderStatus? status) async {
    if (status == null || status == widget.order.status) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(orderActionsProvider).updateStatus(widget.order, status);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Order ${widget.order.orderNumber} is now ${status.label}',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not change the status. ${friendlyErrorMessage(error)}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Status:', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(width: 12),
        DropdownButton<OrderStatus>(
          value: widget.order.status,
          onChanged: _saving ? null : _change,
          items: [
            for (final status in OrderStatus.values)
              DropdownMenuItem(value: status, child: Text(status.label)),
          ],
        ),
        if (_saving) ...[
          const SizedBox(width: 12),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ],
    );
  }
}
