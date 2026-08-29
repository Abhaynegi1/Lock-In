import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Service to keep the device display awake during active strict focus sessions.
/// Encapsulates wakelock_plus with safety guards and state tracking.
class ScreenWakeService {
  static bool _isEnabled = false;

  /// Whether the screen keep-awake lock is currently active.
  static bool get isEnabled => _isEnabled;

  /// Keeps the device screen turned on, preventing automatic sleep/inactivity timeout.
  static Future<void> enable() async {
    if (_isEnabled) return;
    try {
      await WakelockPlus.enable();
      _isEnabled = true;
      debugPrint('[ScreenWakeService] Screen awake enabled');
    } catch (e) {
      debugPrint('[ScreenWakeService] Error enabling screen awake: $e');
    }
  }

  /// Releases the screen keep-awake lock, allowing the screen to turn off normally.
  static Future<void> disable() async {
    if (!_isEnabled) return;
    try {
      await WakelockPlus.disable();
      _isEnabled = false;
      debugPrint('[ScreenWakeService] Screen awake disabled');
    } catch (e) {
      debugPrint('[ScreenWakeService] Error disabling screen awake: $e');
    }
  }

  /// Sets the screen keep-awake lock based on the given boolean flag.
  static Future<void> setEnabled(bool enableWake) async {
    if (enableWake) {
      await enable();
    } else {
      await disable();
    }
  }
}
