import 'package:flutter/material.dart';
import '../models/pokemon.dart';

// Card that shows one Pokemon.
class PokemonCard extends StatelessWidget {
  final Pokemon pokemon;

  const PokemonCard({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            Text(
              '#${pokemon.id.toString().padLeft(3, '0')}',
              style: const TextStyle(color: Colors.grey),
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
            Text(
              // Capitalize the first letter.
              pokemon.name[0].toUpperCase() + pokemon.name.substring(1),
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
