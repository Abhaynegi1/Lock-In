import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Contract for triggering audio and tactile feedback upon focus events.
/// Decouples providers and UI from raw platform audio and haptic drivers.
abstract class CompletionFeedbackService {
  Future<void> onSessionCompleted({
    required String mode,
    required String preset,
  });

  Future<void> onSessionForfeited();

  Future<void> previewPreset(String preset);

  void dispose();
}

/// Default implementation using audioplayers and Flutter system haptics.
class DefaultCompletionFeedbackService implements CompletionFeedbackService {
  static final DefaultCompletionFeedbackService _instance =
      DefaultCompletionFeedbackService._internal();

  factory DefaultCompletionFeedbackService() => _instance;

  AudioPlayer? _player;
  DateTime? _lastCompletionTrigger;

  // Relative cue volume: scales with the user's system volume (never overrides it).
  static const double _relativeCueVolume = 0.5;

  DefaultCompletionFeedbackService._internal();

  AudioPlayer get _audioPlayer {
    _player ??= AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    return _player!;
  }

  static const Map<String, String> _presetAssets = {
    'soft_bell': 'sounds/soft_bell.wav',
    'warm_tone': 'sounds/warm_tone.wav',
    'gentle_chime': 'sounds/gentle_chime.wav',
  };

  String _resolveAsset(String preset) {
    return _presetAssets[preset] ?? 'sounds/soft_bell.wav';
  }

  @override
  Future<void> onSessionCompleted({
    required String mode,
    required String preset,
  }) async {
    // Deduplication guard: prevent duplicate sounds if timer & battle finalize simultaneously
    final now = DateTime.now();
    if (_lastCompletionTrigger != null &&
        now.difference(_lastCompletionTrigger!).inMilliseconds < 1500) {
      debugPrint('[CompletionFeedbackService] Suppressed duplicate completion cue');
      return;
    }
    _lastCompletionTrigger = now;

    if (mode == 'silent') {
      return;
    }

    // Subtle double pulse haptic for both "sound_and_haptics" and "haptics_only" (Library mode)
    unawaited(_triggerSoftDoublePulse());

    if (mode == 'sound_and_haptics') {
      await _playCue(_resolveAsset(preset));
    }
  }

  @override
  Future<void> onSessionForfeited() async {
    // Gentle single tactile pulse on forfeit (never punitive, no failure buzz, no audio)
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  @override
  Future<void> previewPreset(String preset) async {
    await _playCue(_resolveAsset(preset));
  }

  Future<void> _playCue(String assetPath) async {
    try {
      final player = _audioPlayer;
      await player.stop();
      await player.setVolume(_relativeCueVolume);
      await player.play(AssetSource(assetPath), mode: PlayerMode.lowLatency);
    } catch (e) {
      debugPrint('[CompletionFeedbackService] Audio playback error: $e');
    }
  }

  Future<void> _triggerSoftDoublePulse() async {
    try {
      await HapticFeedback.lightImpact();
      await Future.delayed(const Duration(milliseconds: 120));
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  @override
  void dispose() {
    _player?.dispose();
    _player = null;
  }
}
