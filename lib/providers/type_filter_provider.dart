import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pokemon.dart';
import 'pokemon_provider.dart';

// Holds the selected type for the filter. null means no filter (show all).
class TypeFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  // Only show Pokemon with this type.
  void selectType(String type) {
    state = type;
  }

  // Remove the filter and show the full list again.
  void clearFilter() {
    state = null;
  }
}

final typeFilterProvider = NotifierProvider<TypeFilterNotifier, String?>(
  TypeFilterNotifier.new,
);

// All the types found in the loaded Pokemon. Used to make the filter chips.
final pokemonTypesProvider = Provider<List<String>>((ref) {
  final pokemonList = ref.watch(pokemonListProvider).value ?? [];

  // A Set removes the duplicates.
  final types = <String>{};
  for (final pokemon in pokemonList) {
    types.addAll(pokemon.types);
  }
  return types.toList()..sort();
});

// The Pokemon list after the type filter is applied.
// Rebuilds by itself when the list or the selected type changes.
final filteredPokemonProvider = Provider<List<Pokemon>>((ref) {
  final pokemonList = ref.watch(pokemonListProvider).value ?? [];
  final selectedType = ref.watch(typeFilterProvider);

  if (selectedType == null) {
    return pokemonList;
  }
  return pokemonList
      .where((pokemon) => pokemon.types.contains(selectedType))
      .toList();
});
