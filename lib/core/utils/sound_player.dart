import 'package:audioplayers/audioplayers.dart';

class SoundPlayer {
  final AudioPlayer _player = AudioPlayer();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      await _player.setVolume(1.0);
      _isInitialized = true;
    }
  }

  Future<void> playBeep() async {
    try {
      await initialize();
      await _player.stop();
      await _player.play(AssetSource('sounds/beep.mp3'));
    } catch (e) {
      debugPrint('Error playing beep: $e');
    }
  }

  Future<void> playError() async {
    try {
      await initialize();
      await _player.stop();
      await _player.play(AssetSource('sounds/error.mp3'));
    } catch (e) {
      debugPrint('Error playing error sound: $e');
    }
  }

  Future<void> playCustom(String assetPath) async {
    try {
      await initialize();
      await _player.stop();
      await _player.play(AssetSource(assetPath));
    } catch (e) {
      debugPrint('Error playing custom sound: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}

void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}