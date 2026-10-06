import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/pokemon_card.dart';
import '../providers/pokemon_provider.dart';
import '../providers/settings_provider.dart';
import 'pokemon_details_page.dart';

// Main page that shows the Pokemon grid.
class PokedexPage extends StatelessWidget {
  const PokedexPage({super.key});

  // Play or stop the music, show a message if it fails.
  Future<void> toggleMusic(BuildContext context) async {
    final success = await context.read<SettingsProvider>().toggleMusic();
    if (!success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not play music.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pokemonProvider = context.watch<PokemonProvider>();
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        backgroundColor: settings.isDarkMode
            ? Colors.blue[900]
            : Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          // Refresh button, calls the API again.
          IconButton(
            onPressed: pokemonProvider.isLoading
                ? null
                : () => context.read<PokemonProvider>().fetchPokemon(),
            icon: const Icon(Icons.refresh),
          ),
          // Dark/light mode button.
          IconButton(
            onPressed: () => context.read<SettingsProvider>().toggleTheme(),
            icon: Icon(
              settings.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
          ),
          IconButton(
            onPressed: () => toggleMusic(context),
            icon: Icon(settings.isPlaying ? Icons.music_note : Icons.music_off),
          ),
        ],
      ),
      body: buildBody(context, pokemonProvider),
    );
  }

  Widget buildBody(BuildContext context, PokemonProvider pokemonProvider) {
    // Loading state.
    if (pokemonProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error state.
    if (pokemonProvider.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, color: Colors.blue[800], size: 50),
            const SizedBox(height: 8),
            Text('Error: ${pokemonProvider.errorMessage}'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => context.read<PokemonProvider>().fetchPokemon(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty state.
    if (pokemonProvider.pokemonList.isEmpty) {
      return const Center(child: Text('No Pokemon found.'));
    }

    // Success state: grid of Pokemon.
    final pokemonList = pokemonProvider.pokemonList;
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      // Fits more columns on wider screens.
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: pokemonList.length,
      itemBuilder: (context, index) {
        return PokemonCard(
          pokemon: pokemonList[index],
          onTap: () {
            // Save the tapped Pokemon in the provider, then open its page.
            context.read<PokemonProvider>().selectPokemon(pokemonList[index]);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PokemonDetailsPage(),
              ),
            );
          },
        );
      },
    );
  }
}
