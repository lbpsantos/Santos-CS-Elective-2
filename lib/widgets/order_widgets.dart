import 'package:flutter/material.dart';

import '../models/order.dart';

// "Nov 12, 2026 · 3:05 PM"
String formatOrderDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final amPm = date.hour < 12 ? 'AM' : 'PM';
  return '${months[date.month - 1]} ${date.day}, ${date.year} · $hour:$minute $amPm';
}

// A colored chip with the order's status.
class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (status) {
      OrderStatus.done => Colors.green,
      OrderStatus.pending => Colors.orange,
      OrderStatus.cancelled => colors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

// One order: number, date, status and total; tap to see the items.
// [trailing] is used by the admin list for the status picker.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    this.initiallyExpanded = false,
    this.showCustomer = false,
    this.statusControl,
  });

  final Order order;
  final bool initiallyExpanded;
  final bool showCustomer;
  final Widget? statusControl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        shape: const Border(),
        title: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Order ${order.orderNumber}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            OrderStatusChip(status: order.status),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (showCustomer)
              Text(
                order.customerName.isEmpty
                    ? order.customerEmail
                    : '${order.customerName} · ${order.customerEmail}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Text(formatOrderDate(order.createdAt), style: muted),
            Text(
              '${order.itemCount} ${order.itemCount == 1 ? 'book' : 'books'} · '
              '₱${order.total.toStringAsFixed(2)}',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          const Divider(),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${item.quantity} × ₱${item.unitPrice.toStringAsFixed(2)}'
                          '${item.productId == null ? ' · no longer sold' : ''}',
                          style: muted,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₱${item.subtotal.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          const Divider(),
          Row(
            children: [
              Text(
                'Total',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '₱${order.total.toStringAsFixed(2)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          if (statusControl != null) ...[
            const SizedBox(height: 8),
            statusControl!,
          ],
        ],
      ),
    );
  }
}
