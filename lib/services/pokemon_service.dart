import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';

// Handles API calls to PokeAPI.
class PokemonService {
  static const String baseUrl = 'https://pokeapi.co/api/v2/pokemon';

  // Fetch the first 30 Pokemon.
  Future<List<Pokemon>> fetchPokemon() async {
    final response = await http.get(Uri.parse('$baseUrl?limit=30'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List results = data['results'];
      return results.map((item) => Pokemon.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load Pokemon');
    }
  }
}
