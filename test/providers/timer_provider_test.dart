import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lock_in/providers/timer_provider.dart';
import 'package:lock_in/models/focus_session.dart';
import 'package:lock_in/services/storage_service.dart';

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

      await provider.updateUserAvatar('assets/default_pfp/avatar-book.svg');
      expect(provider.userAvatar, 'assets/default_pfp/avatar-book.svg');

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

    test('extendSession successfully completes and updates previous session to 30 mins', () async {
      final storageService = StorageService();
      final provider = TimerProvider(storageService: storageService);
      await Future.delayed(const Duration(milliseconds: 50));

      final baseSession = FocusSession(
        id: 'sess-25',
        durationMinutes: 25,
        targetDurationMinutes: 25,
        dateTime: DateTime.now(),
        isWin: true,
      );
      await storageService.saveSession(baseSession);
      await provider.refreshFromStorage();

      expect(provider.history.first.durationMinutes, 25);
      final initialStreak = provider.currentStreak;

      // Start extending by 5 mins
      provider.extendSession(5);
      expect(provider.isExtending, true);
      expect(provider.baseCompletedMinutes, 25);
      expect(provider.totalSeconds, 300);
      expect(provider.status, SessionStatus.running);

      // Complete the extension
      await provider.completeSessionForTesting(true);

      expect(provider.status, SessionStatus.won);
      expect(provider.isExtending, false);
      expect(provider.totalSeconds, 1800); // 30 mins in seconds
      expect(provider.history.first.durationMinutes, 30);
      expect(provider.history.first.targetDurationMinutes, 30);
      expect(provider.currentStreak, initialStreak); // Streak was not incremented twice

      // Verify in persistent storage as well
      final stored = await storageService.getHistory();
      expect(stored.first.durationMinutes, 30);
    });

    test('extendSession edge case: lockout or forfeit preserves original 25 mins win and protects streak', () async {
      final storageService = StorageService();
      final provider = TimerProvider(storageService: storageService);
      await Future.delayed(const Duration(milliseconds: 50));

      final baseSession = FocusSession(
        id: 'sess-25-safe',
        durationMinutes: 25,
        targetDurationMinutes: 25,
        dateTime: DateTime.now(),
        isWin: true,
      );
      await storageService.saveSession(baseSession);
      await provider.refreshFromStorage();

      final streakBefore = provider.currentStreak;
      expect(provider.history.first.durationMinutes, 25);

      // User extends 5 mins
      provider.extendSession(5);
      expect(provider.isExtending, true);

      // User gets locked out / app paused / ends extension early
      await provider.forfeitSession();

      // EDGE CASE GUARANTEE:
      // Status remains won, session duration remains 25m, streak is NOT reset!
      expect(provider.status, SessionStatus.won);
      expect(provider.extensionInterrupted, true);
      expect(provider.isExtending, false);
      expect(provider.totalSeconds, 25 * 60);
      expect(provider.history.first.durationMinutes, 25);
      expect(provider.history.first.isWin, true);
      expect(provider.currentStreak, streakBefore); // Streak is untouched!

      final stored = await storageService.getHistory();
      expect(stored.first.durationMinutes, 25);
      expect(stored.first.isWin, true);
      expect(await storageService.getStreak(), streakBefore);
    });
  });
}
