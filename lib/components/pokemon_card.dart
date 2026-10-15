import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pokemon.dart';
import '../providers/favorites_provider.dart';
import '../providers/nickname_provider.dart';
import '../providers/settings_provider.dart';

// Card that shows one Pokemon.
class PokemonCard extends ConsumerWidget {
  final Pokemon pokemon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const PokemonCard({
    super.key,
    required this.pokemon,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    // select() so this card only rebuilds when ITS nickname or favorite
    // status changes, not when another Pokemon changes.
    final nickname = ref.watch(
      nicknameProvider.select((nicknames) => nicknames[pokemon.id]),
    );
    final isFavorite = ref.watch(
      favoritesProvider.select(
        (favorites) => favorites.any((p) => p.id == pokemon.id),
      ),
    );

    return Card(
      elevation: 2,
      color: isDark ? const Color(0xFF1B263B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.blue.shade700 : Colors.blue.shade200,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      // Makes the card clickable.
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    '#${pokemon.id.toString().padLeft(3, '0')}',
                    style: TextStyle(
                      color: isDark ? Colors.blue[200] : Colors.blue[400],
                    ),
                  ),
                  const Spacer(),
                  // Small heart, tap it to add/remove from favorites.
                  IconButton(
                    onPressed: () => ref
                        .read(favoritesProvider.notifier)
                        .toggleFavorite(pokemon),
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: isFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                  ),
                ],
              ),
              // Image takes the leftover space so the card never overflows.
              Expanded(
                child: Image.network(
                  pokemon.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 40),
                ),
              ),
              // Original name is always shown.
              Text(
                pokemon.displayName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.blue[900],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              // Nickname is shown under it if there is one.
              if (nickname != null)
                Text(
                  '"$nickname"',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.blue[200] : Colors.blue[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
