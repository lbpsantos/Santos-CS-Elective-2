import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/pokemon.dart';

// Holds the list of favorite Pokemon.
class FavoritesNotifier extends Notifier<List<Pokemon>> {
  @override
  List<Pokemon> build() => [];

  // Check by id, because refreshing the list makes new Pokemon objects.
  bool isFavorite(int pokemonId) {
    return state.any((pokemon) => pokemon.id == pokemonId);
  }

  // Add the Pokemon if it's not a favorite yet, remove it if it already is.
  void toggleFavorite(Pokemon pokemon) {
    if (isFavorite(pokemon.id)) {
      removeFavorite(pokemon.id);
    } else {
      // New list so Riverpod sees the change.
      state = [...state, pokemon];
    }
  }

  void removeFavorite(int pokemonId) {
    state = state.where((pokemon) => pokemon.id != pokemonId).toList();
  }
}

final favoritesProvider = NotifierProvider<FavoritesNotifier, List<Pokemon>>(
  FavoritesNotifier.new,
);

// Whether the favorites panel is open. It's in Riverpod (not setState) so it
// stays open or closed on every page of the app.
class FavoritesPanelNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void togglePanel() {
    state = !state;
  }
}

final favoritesPanelProvider = NotifierProvider<FavoritesPanelNotifier, bool>(
  FavoritesPanelNotifier.new,
);
