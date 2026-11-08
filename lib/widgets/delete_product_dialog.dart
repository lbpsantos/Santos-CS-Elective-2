import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../providers/products_provider.dart';
import '../services/product_service.dart';

// Asks "are you sure?" first, then deletes the book from Supabase.
// Returns true if the book was deleted.
Future<bool> confirmAndDeleteProduct(
  BuildContext context,
  WidgetRef ref,
  Product product,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final colors = Theme.of(dialogContext).colorScheme;
      return AlertDialog(
        title: const Text('Delete Book?'),
        content: Text(
          '"${product.name}" will be removed from the shop. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) return false;

  // Get these before waiting for Supabase. The card that opened this dialog
  // is removed when the list reloads, so its context can't be used after.
  final messenger = ScaffoldMessenger.of(context);
  final actions = ref.read(productActionsProvider);
  try {
    await actions.deleteProduct(product);
    messenger.showSnackBar(
      SnackBar(content: Text('Deleted "${product.name}"')),
    );
    return true;
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Could not delete the book. ${friendlyErrorMessage(error)}',
        ),
      ),
    );
    return false;
  }
}
