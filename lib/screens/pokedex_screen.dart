import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../services/pokemon_service.dart';
import '../widgets/pokemon_card.dart';

// Main screen that shows the Pokemon grid.
class PokedexScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  const PokedexScreen({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  final PokemonService service = PokemonService();
  late Future<List<Pokemon>> futurePokemon;
  final AudioPlayer player = AudioPlayer();
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    // Fetch once so it doesn't reload on every rebuild.
    futurePokemon = service.fetchPokemon();
  }

  // Play or stop the background music.
  Future<void> toggleMusic() async {
    try {
      if (isPlaying) {
        await player.stop();
      } else {
        await player.setReleaseMode(ReleaseMode.loop);
        await player.play(AssetSource('music/bgm.mp3'));
      }
      setState(() => isPlaying = !isPlaying);
    } catch (e) {
      // Shows a message if the music file is missing.
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not play music.')));
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        backgroundColor: widget.isDarkMode
            ? Colors.blue[900]
            : Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          // Dark/light mode button.
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            onPressed: toggleMusic,
            icon: Icon(isPlaying ? Icons.music_note : Icons.music_off),
          ),
        ],
      ),
      body: FutureBuilder<List<Pokemon>>(
        future: futurePokemon,
        builder: (context, snapshot) {
          // Loading state.
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state.
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error, color: Colors.blue[800], size: 50),
                  const SizedBox(height: 8),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        futurePokemon = service.fetchPokemon();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Empty state.
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No Pokemon found.'));
          }

          // Grid of Pokemon.
          final pokemonList = snapshot.data!;
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
              return PokemonCard(pokemon: pokemonList[index]);
            },
          );
        },
      ),
    );
  }
}
