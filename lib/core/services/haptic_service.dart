import 'package:flutter/services.dart';

/// Provides haptic feedback for game events.
/// Uses Flutter's built-in HapticFeedback — no extra package needed.
class HapticService {
  HapticService._();

  /// Light tap — cell placement by local player.
  static void lightImpact() => HapticFeedback.lightImpact();

  /// Medium tap — opponent move received.
  static void mediumImpact() => HapticFeedback.mediumImpact();

  /// Heavy tap — sequence scored (POP!).
  static void heavyImpact() => HapticFeedback.heavyImpact();

  /// Selection click — button taps, UI interactions.
  static void selectionClick() => HapticFeedback.selectionClick();

  /// Long vibration — game over.
  static void vibrate() => HapticFeedback.vibrate();
}
