import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/filter_provider.dart';
import '../providers/products_provider.dart';

// The genre dropdown. The genres come from the Supabase `genres` table, and
// picking one only shows the books with that genre.
class GenreFilter extends ConsumerWidget {
  const GenreFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genres = ref.watch(genresProvider).value;
    final selectedId = ref.watch(productFilterProvider).genreId;

    // Nothing to show while loading, after an error, or with no genres.
    if (genres == null || genres.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    // The dropdown crashes if its value is not one of its items, e.g. when
    // the chosen genre was deleted. Then show "All genres" instead.
    final shownId = genres.any((genre) => genre.id == selectedId)
        ? selectedId
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 8, 0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF26211E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.category_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            'Genre',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButton<int?>(
              value: shownId,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(12),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('All genres'),
                ),
                for (final genre in genres)
                  DropdownMenuItem<int?>(
                    value: genre.id,
                    child: Text(genre.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (genreId) =>
                  ref.read(productFilterProvider.notifier).setGenre(genreId),
            ),
          ),
        ],
      ),
    );
  }
}
