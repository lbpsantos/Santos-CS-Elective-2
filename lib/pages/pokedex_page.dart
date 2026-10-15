import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/favorites_panel.dart';
import '../components/nickname_dialog.dart';
import '../components/pokemon_card.dart';
import '../components/type_filter_bar.dart';
import '../models/pokemon.dart';
import '../providers/pokemon_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/type_filter_provider.dart';
import 'pokemon_details_page.dart';

// Main page that shows the Pokemon grid.
class PokedexPage extends ConsumerWidget {
  const PokedexPage({super.key});

  // Play or stop the music, show a message if it fails.
  Future<void> toggleMusic(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(musicProvider.notifier).toggleMusic();
    if (!success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not play music.')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pokemonAsync = ref.watch(pokemonListProvider);
    final isDark = ref.watch(isDarkModeProvider);
    final isPlaying = ref.watch(musicProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        backgroundColor: isDark ? Colors.blue[900] : Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          // Refresh button, calls fetchPokemon() again.
          IconButton(
            onPressed: pokemonAsync.isLoading
                ? null
                : () => ref.read(pokemonListProvider.notifier).fetchPokemon(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          const FavoritesButton(),
          // Dark/light mode button.
          IconButton(
            onPressed: () =>
                ref.read(isDarkModeProvider.notifier).toggleTheme(),
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            onPressed: () => toggleMusic(context, ref),
            icon: Icon(isPlaying ? Icons.music_note : Icons.music_off),
          ),
        ],
      ),
      body: Column(
        children: [
          const FavoritesPanel(),
          // when() picks which widget to show for each state.
          Expanded(
            child: pokemonAsync.when(
              // Show the spinner again when refreshing (not the old list).
              skipLoadingOnRefresh: false,
              // Loading state.
              loading: () => const Center(child: CircularProgressIndicator()),
              // Error state.
              error: (error, stackTrace) => buildError(ref, error),
              // Success state.
              data: (pokemonList) => buildPokemonGrid(context, ref),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildError(WidgetRef ref, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, color: Colors.blue[800], size: 50),
            const SizedBox(height: 8),
            const Text(
              'Could not load the Pokémon.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            // The actual error, smaller.
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () =>
                  ref.read(pokemonListProvider.notifier).fetchPokemon(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPokemonGrid(BuildContext context, WidgetRef ref) {
    // Already filtered by type in the provider.
    final pokemonList = ref.watch(filteredPokemonProvider);
    final selectedType = ref.watch(typeFilterProvider);

    return Column(
      children: [
        const TypeFilterBar(),
        // Shows what filter is on, with a button to clear it.
        if (selectedType != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Text(
                  'Showing ${capitalize(selectedType)} type (${pokemonList.length})',
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () =>
                      ref.read(typeFilterProvider.notifier).clearFilter(),
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear filter'),
                ),
              ],
            ),
          ),
        Expanded(
          // Pull down to refresh, calls fetchPokemon() again.
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(pokemonListProvider.notifier).fetchPokemon(),
            child: pokemonList.isEmpty
                ? buildEmpty()
                : GridView.builder(
                    // So pull to refresh still works even with few Pokemon.
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    // Fits more columns on wider screens.
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 150,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.8,
                        ),
                    itemCount: pokemonList.length,
                    itemBuilder: (context, index) {
                      final pokemon = pokemonList[index];
                      return PokemonCard(
                        pokemon: pokemon,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PokemonDetailsPage(pokemon: pokemon),
                          ),
                        ),
                        // Long press is a shortcut for the nickname editor.
                        onLongPress: () => showNicknameDialog(context, pokemon),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // Empty state. It's a ListView so pull to refresh still works here.
  Widget buildEmpty() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 100),
        Center(child: Text('No Pokémon found.')),
      ],
    );
  }
}
