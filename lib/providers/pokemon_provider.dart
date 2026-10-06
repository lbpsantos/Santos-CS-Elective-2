import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';

// Holds the Pokemon data and the loading/error states.
class PokemonProvider extends ChangeNotifier {
  static const String baseUrl = 'https://pokeapi.co/api/v2/pokemon';

  List<Pokemon> pokemonList = [];
  bool isLoading = false;
  String? errorMessage;

  // The Pokemon that was tapped (used by the details page).
  Pokemon? selectedPokemon;

  // Fetch the first 30 Pokemon. Also used for refresh.
  Future<void> fetchPokemon() async {
    // Loading state.
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(Uri.parse('$baseUrl?limit=30'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List results = data['results'];
        // Success state.
        pokemonList = results.map((item) => Pokemon.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load Pokemon');
      }
    } catch (e) {
      // Error state.
      errorMessage = e.toString();
    }

    isLoading = false;
    notifyListeners();
  }

  // Save the tapped Pokemon so the details page can read it.
  void selectPokemon(Pokemon pokemon) {
    selectedPokemon = pokemon;
    notifyListeners();
  }
}
