import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lock_in/providers/timer_provider.dart';
import 'package:lock_in/models/focus_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TimerProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        'focus_streak': 3,
        'focus_daily_goal': 180,
        'focus_username': 'Test Runner',
        'focus_strict_anti_distraction': true,
      });
    });

    test('initializes state and formatting calculations properly', () async {
      final provider = TimerProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(provider.currentStreak, 3);
      expect(provider.dailyGoalMinutes, 180);
      expect(provider.userName, 'Test Runner');
      expect(provider.isStrictAntiDistraction, true);
      expect(provider.status, SessionStatus.idle);
      expect(provider.selectedDurationMinutes, 45);
      expect(provider.selectedTimerFormatted, '45:00');
      expect(provider.activeSessionType, SessionType.solo);
    });

    test('updates duration and daily goal', () async {
      final provider = TimerProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      provider.selectDuration(60);
      expect(provider.selectedDurationMinutes, 60);
      expect(provider.selectedTimerFormatted, '60:00');

      await provider.updateDailyGoalMinutes(300);
      expect(provider.dailyGoalMinutes, 300);

      await provider.updateUserName('Champion Focus');
      expect(provider.userName, 'Champion Focus');

      await provider.setStrictAntiDistraction(false);
      expect(provider.isStrictAntiDistraction, false);

      await provider.toggleStrictAntiDistraction();
      expect(provider.isStrictAntiDistraction, true);
    });

    test('createBattle adds battle to list and persists', () async {
      final provider = TimerProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      await provider.createBattle('Sarah Connor', 3);

      expect(provider.battles.length, 1);
      expect(provider.battles.first.opponentName, 'Sarah Connor');
      expect(provider.battles.first.endsIn, '3h');
      expect(provider.battles.first.userMinutes, 0);
    });
  });
}
