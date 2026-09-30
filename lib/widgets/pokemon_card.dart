import 'package:flutter/material.dart';
import '../models/pokemon.dart';

// Card that shows one Pokemon.
class PokemonCard extends StatelessWidget {
  final Pokemon pokemon;

  const PokemonCard({super.key, required this.pokemon});

  @override
  Widget build(BuildContext context) {
    // Check if the app is in dark mode.
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Column(
          children: [
            Text(
              '#${pokemon.id.toString().padLeft(3, '0')}',
              style: TextStyle(
                color: isDark ? Colors.blue[200] : Colors.blue[400],
              ),
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
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.blue[900],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
