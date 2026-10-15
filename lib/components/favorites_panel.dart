import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pokemon.dart';
import '../pages/pokemon_details_page.dart';
import '../providers/favorites_provider.dart';
import '../providers/nickname_provider.dart';
import '../providers/settings_provider.dart';

// AppBar button that opens/closes the favorites panel.
// Shows how many favorites there are on a small badge.
class FavoritesButton extends ConsumerWidget {
  const FavoritesButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = ref.watch(favoritesPanelProvider);
    final count = ref.watch(favoritesProvider).length;

    return IconButton(
      onPressed: () => ref.read(favoritesPanelProvider.notifier).togglePanel(),
      tooltip: isOpen ? 'Hide favorites' : 'Show favorites',
      icon: Badge(
        label: Text('$count'),
        isLabelVisible: count > 0,
        child: Icon(isOpen ? Icons.expand_less : Icons.favorite),
      ),
    );
  }
}

// Panel under the AppBar that shows the favorite Pokemon.
// Put at the top of every page so it can be used all throughout the app.
class FavoritesPanel extends ConsumerWidget {
  const FavoritesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = ref.watch(favoritesPanelProvider);
    final favorites = ref.watch(favoritesProvider);
    final nicknames = ref.watch(nicknameProvider);
    final isDark = ref.watch(isDarkModeProvider);

    // AnimatedSize makes it slide open and closed.
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      alignment: Alignment.topCenter,
      child: !isOpen
          ? const SizedBox(width: double.infinity)
          : Container(
              width: double.infinity,
              color: isDark ? const Color(0xFF1B263B) : Colors.blue[100],
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Favorites (${favorites.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Empty state.
                  if (favorites.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No favorite Pokémon yet. Tap the heart on a card to add one.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 130,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: favorites.length,
                        itemBuilder: (context, index) {
                          final pokemon = favorites[index];
                          final nickname = nicknames[pokemon.id];

                          return FavoriteTile(
                            pokemon: pokemon,
                            nickname: nickname,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

// One small card inside the favorites panel.
class FavoriteTile extends ConsumerWidget {
  final Pokemon pokemon;
  final String? nickname;

  const FavoriteTile({super.key, required this.pokemon, this.nickname});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);

    return Card(
      color: isDark ? const Color(0xFF0D1B2A) : Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Open the Pokemon's details page.
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PokemonDetailsPage(pokemon: pokemon),
          ),
        ),
        child: SizedBox(
          width: 100,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 2, 6),
            child: Column(
              children: [
                // Top row: id on the left, x button on the right.
                Row(
                  children: [
                    Text(
                      '#${pokemon.id.toString().padLeft(3, '0')}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.blue[200] : Colors.blue[400],
                      ),
                    ),
                    const Spacer(),
                    // Small x to remove from favorites.
                    InkWell(
                      onTap: () => ref
                          .read(favoritesProvider.notifier)
                          .removeFavorite(pokemon.id),
                      customBorder: const CircleBorder(),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.close, size: 16),
                      ),
                    ),
                  ],
                ),
                // Image fills the middle.
                Expanded(
                  child: Image.network(
                    pokemon.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image),
                  ),
                ),
                // Original name, and the nickname under it if there is one.
                Text(
                  pokemon.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (nickname != null)
                  Text(
                    '"$nickname"',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
