import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pokemon_provider.dart';
import '../providers/settings_provider.dart';

// Page that shows one Pokemon. The data comes from the provider.
class PokemonDetailsPage extends StatelessWidget {
  const PokemonDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pokemon = context.watch<PokemonProvider>().selectedPokemon;
    final isDark = context.watch<SettingsProvider>().isDarkMode;

    // Just in case nothing was selected.
    if (pokemon == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pokemon')),
        body: const Center(child: Text('No Pokemon selected.')),
      );
    }

    // Capitalize the first letter.
    final name = pokemon.name[0].toUpperCase() + pokemon.name.substring(1);

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: isDark ? Colors.blue[900] : Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          color: isDark ? const Color(0xFF1B263B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? Colors.blue.shade700 : Colors.blue.shade200,
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
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.blue[900],
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
