import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../providers/products_provider.dart';
import '../services/product_service.dart';

// Opens the form to add a book, or to edit [product] if one is given.
// Returns the saved book, or null if the form was closed without saving.
Future<Product?> showProductForm(BuildContext context, {Product? product}) {
  return showModalBottomSheet<Product>(
    context: context,
    // Lets the sheet grow so the fields stay above the keyboard.
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => ProductFormSheet(product: product),
  );
}

// The add / edit book form. Saving goes through productActionsProvider.
class ProductFormSheet extends ConsumerStatefulWidget {
  const ProductFormSheet({super.key, this.product});

  // The book being edited, or null when adding a new book.
  final Product? product;

  @override
  ConsumerState<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _author;
  late final TextEditingController _price;
  late final TextEditingController _rating;
  late final TextEditingController _imageUrl;
  late final TextEditingController _description;
  // The genre picked in the dropdown (null = no genre).
  late int? _genreId = widget.product?.genreId;

  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    // Start with the book's current values when editing.
    final book = widget.product;
    _name = TextEditingController(text: book?.name);
    _author = TextEditingController(text: book?.author);
    _price = TextEditingController(text: book?.price.toStringAsFixed(2));
    _rating = TextEditingController(
      text: book == null || book.rating == 0 ? '' : '${book.rating}',
    );
    _imageUrl = TextEditingController(text: book?.imageUrl);
    _description = TextEditingController(text: book?.description);
  }

  @override
  void dispose() {
    _name.dispose();
    _author.dispose();
    _price.dispose();
    _rating.dispose();
    _imageUrl.dispose();
    _description.dispose();
    super.dispose();
  }

  // Accepts "1,299.50" or "₱499" as well as plain numbers.
  double? _parseNumber(String text) {
    return double.tryParse(text.replaceAll(RegExp(r'[₱,\s]'), ''));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final product = Product(
      id: widget.product?.id,
      name: _name.text.trim(),
      author: _author.text.trim(),
      price: _parseNumber(_price.text)!,
      rating: _parseNumber(_rating.text) ?? 0,
      genreId: _genreId,
      imageUrl: _imageUrl.text.trim(),
      description: _description.text.trim(),
    );

    try {
      final actions = ref.read(productActionsProvider);
      final saved = _isEditing
          ? await actions.updateProduct(product)
          : await actions.addProduct(product);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Saved changes to "${saved.name}"'
                : 'Added "${saved.name}"',
          ),
        ),
      );
      Navigator.pop(context, saved);
    } catch (error) {
      // Keep the form open so nothing that was typed is lost.
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = friendlyErrorMessage(error);
      });
    }
  }

  String? _validatePrice(String? text) {
    final price = _parseNumber(text ?? '');
    if (price == null) return 'Enter a price, e.g. 499';
    if (price <= 0) return 'The price must be more than 0';
    if (price >= 100000000) return 'That price is too high';
    return null;
  }

  String? _validateRating(String? text) {
    if (text == null || text.trim().isEmpty) return null; // optional
    final rating = _parseNumber(text);
    if (rating == null || rating < 0 || rating > 5) return 'Use 0 to 5';
    return null;
  }

  String? _validateImageUrl(String? text) {
    final url = text?.trim() ?? '';
    if (url.isEmpty) return null; // optional
    if (url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('lib/assets/')) {
      return null;
    }
    return 'Use a link that starts with https://';
  }

  FormFieldValidator<String> _required(String message) {
    return (text) => text == null || text.trim().isEmpty ? message : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      // Push the form up when the keyboard opens.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? 'Edit Book' : 'Add a Book',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildField(
                _name,
                'Title',
                validator: _required('Enter the title'),
              ),
              _buildField(
                _author,
                'Author',
                validator: _required('Enter the author'),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildField(
                      _price,
                      'Price (₱)',
                      isNumber: true,
                      validator: _validatePrice,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildField(
                      _rating,
                      'Rating (0-5)',
                      isNumber: true,
                      validator: _validateRating,
                    ),
                  ),
                ],
              ),
              _buildGenreField(),
              _buildField(
                _imageUrl,
                'Cover image link (optional)',
                hint: 'https://...',
                validator: _validateImageUrl,
              ),
              _buildField(_description, 'Description (optional)', maxLines: 4),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: Text(_isEditing ? 'Save Changes' : 'Add Book'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // A dropdown with the genres from the Supabase `genres` table.
  Widget _buildGenreField() {
    final genresAsync = ref.watch(genresProvider);
    final genres = genresAsync.value;

    if (genres == null) {
      // Still loading, or the genres could not be loaded.
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InputDecorator(
          decoration: const InputDecoration(labelText: 'Genre'),
          child: Text(
            genresAsync.hasError
                ? 'Could not load the genres'
                : 'Loading genres...',
          ),
        ),
      );
    }

    // The dropdown crashes if its value is not one of its items (e.g. the
    // book's genre was deleted), so start with "No genre" in that case.
    final startId = genres.any((genre) => genre.id == _genreId)
        ? _genreId
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int?>(
        initialValue: startId,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Genre'),
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('No genre')),
          for (final genre in genres)
            DropdownMenuItem<int?>(value: genre.id, child: Text(genre.name)),
        ],
        onChanged: _saving ? null : (genreId) => _genreId = genreId,
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    String? hint,
    bool isNumber = false,
    int maxLines = 1,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: !_saving,
        maxLines: maxLines,
        validator: validator,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
        textInputAction: maxLines > 1
            ? TextInputAction.newline
            : TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          // Puts the label at the top of the big description box
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }
}
