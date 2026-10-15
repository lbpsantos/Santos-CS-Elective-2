import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';

// Handles loading the Pokemon list from the API.
// The state is an AsyncValue, so it can be loading, data or error.
class PokemonListNotifier extends AsyncNotifier<List<Pokemon>> {
  static const String baseUrl = 'https://pokeapi.co/api/v2/pokemon';

  // Runs the first time the provider is used, so the list loads on startup.
  @override
  Future<List<Pokemon>> build() => _getPokemonFromApi();

  // Fetch the Pokemon again. Used by the refresh button and pull to refresh.
  Future<void> fetchPokemon() async {
    // Loading state.
    state = const AsyncLoading();
    // guard() catches any error and turns it into an AsyncError (error state).
    state = await AsyncValue.guard(_getPokemonFromApi);
  }

  // Get the first 30 Pokemon from the API.
  Future<List<Pokemon>> _getPokemonFromApi() async {
    final response = await http
        .get(Uri.parse('$baseUrl?limit=30'))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Server returned ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final List results = data['results'];

    // The list only has the name and url, so we also need each Pokemon's
    // details to get its types. Future.wait sends all requests at the same
    // time instead of one by one.
    return Future.wait(
      results.map((item) => _getPokemonDetails(item['url'] as String)),
    );
  }

  // Get one Pokemon's details (id, name, types).
  Future<Pokemon> _getPokemonDetails(String url) async {
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Server returned ${response.statusCode}');
    }

    return Pokemon.fromJson(jsonDecode(response.body));
  }
}

final pokemonListProvider =
    AsyncNotifierProvider<PokemonListNotifier, List<Pokemon>>(
      PokemonListNotifier.new,
      // Riverpod 3 retries failed providers automatically. We turn that off so
      // the error message shows right away and the user can press Retry.
      retry: (retryCount, error) => null,
    );
