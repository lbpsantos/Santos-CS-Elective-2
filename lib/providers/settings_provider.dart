import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

// Holds the app settings (dark mode and music).
class SettingsProvider extends ChangeNotifier {
  final AudioPlayer player = AudioPlayer();

  bool isDarkMode = false;
  bool isPlaying = false;

  // Switch between light and dark mode.
  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  // Play or stop the background music. Returns false if it failed.
  Future<bool> toggleMusic() async {
    try {
      if (isPlaying) {
        await player.stop();
      } else {
        await player.setReleaseMode(ReleaseMode.loop);
        await player.play(AssetSource('music/bgm.mp3'));
      }
      isPlaying = !isPlaying;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}
