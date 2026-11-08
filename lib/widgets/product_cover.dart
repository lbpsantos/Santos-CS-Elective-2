import 'package:flutter/material.dart';

// Shows a book cover from a web link (https://...) or from lib/assets/.
// If the book has no cover, or the picture can't load, a book icon is shown.
class ProductCover extends StatelessWidget {
  const ProductCover({super.key, required this.imageUrl, this.iconSize = 36});

  final String imageUrl;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final placeholder = Container(
      color: colors.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.menu_book,
        size: iconSize,
        color: colors.onSurfaceVariant,
      ),
    );

    final url = imageUrl.trim();
    if (url.isEmpty) return placeholder;

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return ColoredBox(
        // Shown behind the cover while it downloads.
        color: colors.surfaceContainerHighest,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          // On Flutter web, some image sites don't allow Flutter to draw
          // their pictures (CORS). This shows them with a normal <img> tag.
          webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
          errorBuilder: (context, error, stackTrace) => placeholder,
        ),
      );
    }

    return Image.asset(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => placeholder,
    );
  }
}
