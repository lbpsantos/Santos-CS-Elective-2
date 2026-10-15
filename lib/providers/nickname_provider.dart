import 'package:flutter_riverpod/flutter_riverpod.dart';

// Holds the nicknames, saved by Pokemon id. Example: {25: 'Sparky'}
class NicknameNotifier extends Notifier<Map<int, String>> {
  @override
  Map<int, String> build() => {};

  // Add or edit a nickname. An empty nickname removes it.
  void setNickname(int pokemonId, String nickname) {
    final newNickname = nickname.trim();
    if (newNickname.isEmpty) {
      removeNickname(pokemonId);
      return;
    }
    // Make a new map so Riverpod sees the change and updates the UI.
    state = {...state, pokemonId: newNickname};
  }

  // Remove the nickname of a Pokemon.
  void removeNickname(int pokemonId) {
    state = {...state}..remove(pokemonId);
  }
}

final nicknameProvider = NotifierProvider<NicknameNotifier, Map<int, String>>(
  NicknameNotifier.new,
);
