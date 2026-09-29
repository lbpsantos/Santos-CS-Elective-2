import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../services/pokemon_service.dart';
import '../widgets/pokemon_card.dart';

// Main screen that shows the Pokemon grid.
class PokedexScreen extends StatefulWidget {
  const PokedexScreen({super.key});

  @override
  State<PokedexScreen> createState() => _PokedexScreenState();
}

class _PokedexScreenState extends State<PokedexScreen> {
  final PokemonService service = PokemonService();
  late Future<List<Pokemon>> futurePokemon;

  @override
  void initState() {
    super.initState();
    // Fetch once so it doesn't reload on every rebuild.
    futurePokemon = service.fetchPokemon();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
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
                  const Icon(Icons.error, color: Colors.red, size: 50),
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
