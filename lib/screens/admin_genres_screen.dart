import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/genre.dart';
import '../providers/auth_provider.dart';
import '../providers/products_provider.dart';
import '../services/product_service.dart';
import '../widgets/state_views.dart';

// Add, rename and delete genres (the shop's categories). Admins only.
class AdminGenresScreen extends ConsumerWidget {
  const AdminGenresScreen({super.key});

  Future<void> _addGenre(BuildContext context, WidgetRef ref) async {
    final name = await _askForName(context, title: 'Add Genre');
    if (name == null || !context.mounted) return;
    await _run(
      context,
      () => ref.read(genreActionsProvider).addGenre(name),
      'Added "$name"',
    );
  }

  Future<void> _renameGenre(
    BuildContext context,
    WidgetRef ref,
    Genre genre,
  ) async {
    final name = await _askForName(
      context,
      title: 'Rename Genre',
      initial: genre.name,
    );
    if (name == null || name == genre.name || !context.mounted) return;
    await _run(
      context,
      () => ref.read(genreActionsProvider).renameGenre(genre, name),
      'Renamed to "$name"',
    );
  }

  Future<void> _deleteGenre(
    BuildContext context,
    WidgetRef ref,
    Genre genre,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete "${genre.name}"?'),
        content: const Text(
          'Books in this genre are kept, but will have no genre.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _run(
      context,
      () => ref.read(genreActionsProvider).deleteGenre(genre),
      'Deleted "${genre.name}"',
    );
  }

  // Runs a change and shows the result (or the error) in a SnackBar.
  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
    String done,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      messenger.showSnackBar(SnackBar(content: Text(done)));
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isAdminProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Genres')),
        body: const NoAccessView(message: 'Only admins can manage genres.'),
      );
    }

    final genresAsync = ref.watch(genresProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Genres')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addGenre(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Genre'),
      ),
      body: genresAsync.when(
        loading: () => const LoadingView(),
        error: (error, _) => ErrorView(
          title: 'Could not load the genres',
          message: friendlyErrorMessage(error),
          onRetry: () => ref.invalidate(genresProvider),
        ),
        data: (genres) => genres.isEmpty
            ? const MessageView(
                icon: Icons.category_outlined,
                title: 'No genres yet',
                message: 'Tap "Add Genre" to make the first one.',
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                itemCount: genres.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final genre = genres[index];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.category_outlined),
                      title: Text(genre.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Rename',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _renameGenre(context, ref, genre),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: Icon(
                              Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () => _deleteGenre(context, ref, genre),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// A small dialog with one text field. Returns the name, or null.
Future<String?> _askForName(
  BuildContext context, {
  required String title,
  String initial = '',
}) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => _NameDialog(title: title, initial: initial),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Genre name'),
          onFieldSubmitted: (_) => _submit(),
          validator: (text) =>
              (text ?? '').trim().isEmpty ? 'Enter a name' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
