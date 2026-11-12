import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/products_provider.dart';
import '../services/product_service.dart';
import '../widgets/product_cover.dart';
import '../widgets/state_views.dart';

// The add / edit book form (admins only).
// When editing, every field starts with the book's current value.
class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.product});

  // The book being edited, or null when adding a new book.
  final Product? product;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _author;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _rating;
  late final TextEditingController _imageUrl;
  late final TextEditingController _description;
  // The genre picked in the dropdown (null = no genre).
  late int? _genreId = widget.product?.genreId;

  // A cover picked from the device, uploaded to Supabase Storage on save.
  Uint8List? _pickedBytes;
  String? _pickedName;

  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final book = widget.product;
    _name = TextEditingController(text: book?.name);
    _author = TextEditingController(text: book?.author);
    _price = TextEditingController(text: book?.price.toStringAsFixed(2));
    _stock = TextEditingController(text: book == null ? '' : '${book.stock}');
    _rating = TextEditingController(
      text: book == null || book.rating == 0 ? '' : '${book.rating}',
    );
    _imageUrl = TextEditingController(text: book?.imageUrl);
    _description = TextEditingController(text: book?.description);
    // Redraw the cover preview when a link is typed.
    _imageUrl.addListener(_redraw);
  }

  void _redraw() => setState(() {});

  @override
  void dispose() {
    _imageUrl.removeListener(_redraw);
    _name.dispose();
    _author.dispose();
    _price.dispose();
    _stock.dispose();
    _rating.dispose();
    _imageUrl.dispose();
    _description.dispose();
    super.dispose();
  }

  // Accepts "1,299.50" or "₱499" as well as plain numbers.
  double? _parseNumber(String text) {
    return double.tryParse(text.replaceAll(RegExp(r'[₱,\s]'), ''));
  }

  Future<void> _pickCover() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (file == null) return; // cancelled
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _pickedBytes = bytes;
        _pickedName = file.name;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the picture: $error')),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final actions = ref.read(productActionsProvider);
    try {
      // Upload the picked cover first, then save its link with the book.
      var imageUrl = _imageUrl.text.trim();
      if (_pickedBytes != null) {
        imageUrl = await actions.uploadCover(_pickedBytes!, _pickedName!);
      }

      final product = Product(
        id: widget.product?.id,
        name: _name.text.trim(),
        author: _author.text.trim(),
        price: _parseNumber(_price.text)!,
        stock: int.parse(_stock.text.trim()),
        rating: _parseNumber(_rating.text) ?? 0,
        genreId: _genreId,
        imageUrl: imageUrl,
        description: _description.text.trim(),
      );

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
      context.pop(saved);
    } catch (error) {
      // Keep the form open so nothing that was typed is lost.
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = friendlyErrorMessage(error);
      });
    }
  }

  // Price: a number of zero or more.
  String? _validatePrice(String? text) {
    final price = _parseNumber(text ?? '');
    if (price == null) return 'Enter a price, e.g. 499';
    if (price < 0) return 'The price can\'t be below 0';
    if (price >= 100000000) return 'That price is too high';
    return null;
  }

  // Stock: a whole number of zero or more.
  String? _validateStock(String? text) {
    final value = text?.trim() ?? '';
    if (value.isEmpty) return 'Enter the stock, e.g. 10';
    final stock = int.tryParse(value);
    if (stock == null) return 'Use a whole number';
    if (stock < 0) return 'The stock can\'t be below 0';
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
    if (url.isEmpty || _pickedBytes != null) return null; // optional
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
    // The router already keeps customers out; this is a second check.
    if (!ref.watch(isAdminProvider)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book Form')),
        body: const NoAccessView(message: 'Only admins can add or edit books.'),
      );
    }

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Book' : 'Add a Book')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCoverPicker(theme),
                  const SizedBox(height: 20),
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
                          keyboard: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: _validatePrice,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          _stock,
                          'Stock',
                          keyboard: TextInputType.number,
                          validator: _validateStock,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildGenreField()),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          _rating,
                          'Rating (0-5)',
                          keyboard: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: _validateRating,
                        ),
                      ),
                    ],
                  ),
                  _buildField(
                    _description,
                    'Description (optional)',
                    maxLines: 4,
                  ),
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : () => context.pop(),
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
        ),
      ),
    );
  }

  // The cover preview, an "Upload cover" button and a link field.
  Widget _buildCoverPicker(ThemeData theme) {
    final preview = _pickedBytes != null
        ? Image.memory(_pickedBytes!, fit: BoxFit.cover)
        : ProductCover(imageUrl: _imageUrl.text, iconSize: 40);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(width: 96, height: 144, child: preview),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Cover image',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _saving ? null : _pickCover,
                icon: const Icon(Icons.upload_outlined),
                label: Text(
                  _pickedBytes == null ? 'Upload cover' : 'Choose another',
                ),
              ),
              if (_pickedName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _pickedName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _imageUrl,
                enabled: !_saving && _pickedBytes == null,
                validator: _validateImageUrl,
                decoration: const InputDecoration(
                  labelText: 'or paste a link',
                  hintText: 'https://...',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // A dropdown with the genres from the Supabase `genres` table.
  Widget _buildGenreField() {
    final genresAsync = ref.watch(genresProvider);
    final genres = genresAsync.value;

    if (genres == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InputDecorator(
          decoration: const InputDecoration(labelText: 'Genre'),
          child: Text(
            genresAsync.hasError ? 'Could not load' : 'Loading...',
            maxLines: 1,
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
            DropdownMenuItem<int?>(
              value: genre.id,
              child: Text(genre.name, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: _saving ? null : (genreId) => _genreId = genreId,
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
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
        keyboardType:
            keyboard ??
            (maxLines > 1 ? TextInputType.multiline : TextInputType.text),
        textInputAction: maxLines > 1
            ? TextInputAction.newline
            : TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }
}
