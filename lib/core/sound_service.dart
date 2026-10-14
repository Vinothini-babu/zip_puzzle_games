import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'game_state.dart';

/// Real bundled sound effects.
/// - one dedicated player per sound (a coin never cuts off a click, etc.)
/// - errors are PRINTED in the debug console (before they were silently
///   swallowed, so you could never see why a sound did not play).
class SoundService {
  static final Map<String, AudioPlayer> _players = {};

  static Future<void> _play(String file, double volume) async {
    if (!GameState.instance.sound) return;
    try {
      final p = _players.putIfAbsent(file, () => AudioPlayer());
      await p.stop();
      await p.play(AssetSource('sounds/$file'), volume: volume);
    } catch (e) {
      debugPrint('SoundService: could not play $file -> $e');
    }
  }

  /// Optional: call once in main() after WidgetsFlutterBinding.ensureInitialized()
  /// so the first sound has no delay.
  static Future<void> init() async {
    try {
      await AudioCache.instance.loadAll([
        'sounds/click.wav',
        'sounds/coin.wav',
        'sounds/step.wav',
        'sounds/wrong.wav',
        'sounds/win.wav',
      ]);
    } catch (e) {
      debugPrint('SoundService: preload failed -> $e');
    }
  }

  static Future<void> playClick() => _play('click.wav', 0.6);
  static Future<void> playCoin() => _play('coin.wav', 0.7);
  static Future<void> playStep() => _play('step.wav', 0.35); // each path cell
  static Future<void> playWrong() => _play('wrong.wav', 0.6); // wrong number
  static Future<void> playWin() => _play('win.wav', 0.8); // puzzle solved
}