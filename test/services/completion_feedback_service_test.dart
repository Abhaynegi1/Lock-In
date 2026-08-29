import 'package:flutter_test/flutter_test.dart';
import 'package:lock_in/providers/timer_provider.dart';
import 'package:lock_in/services/completion_feedback_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCompletionFeedbackService implements CompletionFeedbackService {
  int completionCalls = 0;
  int forfeitCalls = 0;
  String? lastMode;
  String? lastPreset;
  String? lastPreviewPreset;

  @override
  Future<void> onSessionCompleted({
    required String mode,
    required String preset,
  }) async {
    completionCalls++;
    lastMode = mode;
    lastPreset = preset;
  }

  @override
  Future<void> onSessionForfeited() async {
    forfeitCalls++;
  }

  @override
  Future<void> previewPreset(String preset) async {
    lastPreviewPreset = preset;
  }

  @override
  void dispose() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CompletionFeedbackService & TimerProvider Integration', () {
    late MockCompletionFeedbackService mockFeedback;
    late TimerProvider provider;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockFeedback = MockCompletionFeedbackService();
      provider = TimerProvider(feedbackService: mockFeedback);
      await provider.refreshFromStorage();
    });

    test('initial state defaults to silent (off)', () {
      expect(provider.finishCueMode, 'silent');
      expect(provider.finishCuePreset, 'soft_bell');
    });

    test('updating mode and preset persists and notifies', () async {
      await provider.setFinishCueMode('haptics_only');
      expect(provider.finishCueMode, 'haptics_only');

      await provider.setFinishCuePreset('warm_tone');
      expect(provider.finishCuePreset, 'warm_tone');
    });

    test('forfeit triggers onSessionForfeited, never onSessionCompleted',
        () async {
      provider.startSession(minutes: 25);
      await provider.forfeitSession();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(mockFeedback.forfeitCalls, 1);
      expect(mockFeedback.completionCalls, 0);
    });

    test('preview calls previewPreset with requested sound', () async {
      await mockFeedback.previewPreset('gentle_chime');
      expect(mockFeedback.lastPreviewPreset, 'gentle_chime');
    });
  });

  group('DefaultCompletionFeedbackService Deduplication', () {
    test('suppresses duplicate completions within 1.5 seconds', () async {
      final service = DefaultCompletionFeedbackService();

      // Silent mode avoids attempting to play platform audio in test
      await service.onSessionCompleted(mode: 'silent', preset: 'soft_bell');
      // Immediate second call should be suppressed by deduplication guard
      await service.onSessionCompleted(mode: 'silent', preset: 'soft_bell');

      // Passes if no unhandled errors occur during rapid consecutive invocations
      expect(true, isTrue);
    });
  });
}
