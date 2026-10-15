import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Holds the dark mode setting.
class ThemeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  // Switch between light and dark mode.
  void toggleTheme() {
    state = !state;
  }
}

final isDarkModeProvider = NotifierProvider<ThemeNotifier, bool>(
  ThemeNotifier.new,
);

// Holds the background music player. The state is true if music is playing.
class MusicNotifier extends Notifier<bool> {
  late AudioPlayer player;

  @override
  bool build() {
    player = AudioPlayer();
    // Free the audio player when the provider is destroyed.
    ref.onDispose(player.dispose);
    return false;
  }

  // Play or stop the background music. Returns false if it failed.
  Future<bool> toggleMusic() async {
    try {
      if (state) {
        await player.stop();
      } else {
        await player.setReleaseMode(ReleaseMode.loop);
        await player.play(AssetSource('music/bgm.mp3'));
      }
      state = !state;
      return true;
    } catch (e) {
      return false;
    }
  }
}

final musicProvider = NotifierProvider<MusicNotifier, bool>(MusicNotifier.new);
