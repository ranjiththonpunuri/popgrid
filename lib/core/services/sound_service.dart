import 'package:audioplayers/audioplayers.dart';

/// Manages game sound effects.
///
/// Sound files should be placed in assets/sounds/.
/// If a sound file is missing, playback silently fails (no crash).
class SoundService {
  SoundService._();

  static final AudioPlayer _player = AudioPlayer();
  static bool enabled = true;

  /// Short tick on cell placement.
  static Future<void> playPlace() => _play('place.mp3');

  /// Pop/ding when a sequence is scored.
  static Future<void> playScore() => _play('score.mp3');

  /// Fanfare on game over.
  static Future<void> playGameOver() => _play('game_over.mp3');

  /// Subtle notification when opponent places a move.
  static Future<void> playOpponentMove() => _play('opponent_move.mp3');

  static Future<void> _play(String filename) async {
    if (!enabled) return;
    try {
      await _player.play(AssetSource('sounds/$filename'));
    } catch (_) {
      // Silently ignore missing audio files
    }
  }

  static void dispose() {
    _player.dispose();
  }
}
