import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/favorites_panel.dart';
import '../components/nickname_dialog.dart';
import '../models/pokemon.dart';
import '../providers/favorites_provider.dart';
import '../providers/nickname_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/type_colors.dart';

// Page that shows one Pokemon. Nickname and favorite come from Riverpod.
class PokemonDetailsPage extends ConsumerWidget {
  final Pokemon pokemon;

  const PokemonDetailsPage({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final nickname = ref.watch(
      nicknameProvider.select((nicknames) => nicknames[pokemon.id]),
    );
    final isFavorite = ref.watch(
      favoritesProvider.select(
        (favorites) => favorites.any((p) => p.id == pokemon.id),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        // Show the nickname in the title if it has one.
        title: Text(nickname ?? pokemon.displayName),
        backgroundColor: isDark ? Colors.blue[900] : Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          // Add/remove this Pokemon from favorites.
          IconButton(
            onPressed: () =>
                ref.read(favoritesProvider.notifier).toggleFavorite(pokemon),
            icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
          ),
          const FavoritesButton(),
        ],
      ),
      body: Column(
        children: [
          const FavoritesPanel(),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(16),
                  color: isDark ? const Color(0xFF1B263B) : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark
                          ? Colors.blue.shade700
                          : Colors.blue.shade200,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '#${pokemon.id.toString().padLeft(3, '0')}',
                          style: TextStyle(
                            fontSize: 20,
                            color: isDark ? Colors.blue[200] : Colors.blue[400],
                          ),
                        ),
                        Image.network(
                          pokemon.imageUrl,
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                          // Keeps the sprite sharp when made bigger.
                          filterQuality: FilterQuality.none,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.broken_image, size: 80),
                        ),
                        // Original name.
                        Text(
                          pokemon.displayName,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.blue[900],
                          ),
                        ),
                        // Nickname (if there is one).
                        if (nickname != null)
                          Text(
                            '"$nickname"',
                            style: TextStyle(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              color: isDark
                                  ? Colors.blue[200]
                                  : Colors.blue[600],
                            ),
                          ),
                        const SizedBox(height: 12),
                        // Type chips.
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final type in pokemon.types)
                              Chip(
                                label: Text(
                                  capitalize(type),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: typeColor(type),
                                side: BorderSide.none,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => showNicknameDialog(context, pokemon),
                          icon: const Icon(Icons.edit),
                          label: Text(
                            nickname == null ? 'Add Nickname' : 'Edit Nickname',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
