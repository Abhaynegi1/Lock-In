import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lock_in/models/battle_model.dart';
import 'package:lock_in/models/focus_session.dart';
import 'package:lock_in/services/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StorageService Tests', () {
    late StorageService storageService;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
    });

    test('saves and gets username', () async {
      expect(await storageService.getUserName(), 'Lock In Member');
      await storageService.saveUserName('Alex Dev');
      expect(await storageService.getUserName(), 'Alex Dev');
    });

    test('saves and gets strict anti distraction setting', () async {
      expect(await storageService.getStrictAntiDistraction(), true);
      await storageService.saveStrictAntiDistraction(false);
      expect(await storageService.getStrictAntiDistraction(), false);
    });

    test('saves winning session and increments streak', () async {
      final session = FocusSession(
        id: 's-1',
        durationMinutes: 45,
        targetDurationMinutes: 45,
        dateTime: DateTime.now(),
        isWin: true,
      );

      await storageService.saveSession(session);
      expect(await storageService.getStreak(), 1);

      final history = await storageService.getHistory();
      expect(history.length, 1);
      expect(history.first.id, 's-1');
    });

    test('saves losing session and resets streak', () async {
      final winSession = FocusSession(
        id: 's-win',
        durationMinutes: 45,
        targetDurationMinutes: 45,
        dateTime: DateTime.now(),
        isWin: true,
      );
      await storageService.saveSession(winSession);
      expect(await storageService.getStreak(), 1);

      final lossSession = FocusSession(
        id: 's-loss',
        durationMinutes: 10,
        targetDurationMinutes: 45,
        dateTime: DateTime.now(),
        isWin: false,
      );
      await storageService.saveSession(lossSession);
      expect(await storageService.getStreak(), 0);
    });

    test('saves and gets battles list', () async {
      const battle = BattleModel(
        id: 'custom-battle-1',
        opponentName: 'Rival',
        opponentInitials: 'R',
        userMinutes: 20,
        opponentMinutes: 40,
        endsIn: 'ends in 1h',
      );

      await storageService.saveBattles([battle]);
      final fetched = await storageService.getBattles();
      expect(fetched.length, 1);
      expect(fetched.first.id, 'custom-battle-1');
      expect(fetched.first.opponentName, 'Rival');
    });

    test('clearHistory clears history, streak, and battles', () async {
      final session = FocusSession(
        id: 's-clear',
        durationMinutes: 30,
        dateTime: DateTime.now(),
        isWin: true,
      );
      await storageService.saveSession(session);
      await storageService.clearHistory();

      expect(await storageService.getStreak(), 0);
      expect((await storageService.getHistory()).isEmpty, true);
      expect((await storageService.getBattles()).isEmpty, true);
    });

    test('updateSession updates existing session in history without altering streak', () async {
      final session = FocusSession(
        id: 's-update',
        durationMinutes: 25,
        targetDurationMinutes: 25,
        dateTime: DateTime.now(),
        isWin: true,
      );
      await storageService.saveSession(session);
      expect(await storageService.getStreak(), 1);

      final updated = session.copyWith(
        durationMinutes: 30,
        targetDurationMinutes: 30,
      );
      await storageService.updateSession(updated);

      expect(await storageService.getStreak(), 1); // Streak unchanged
      final history = await storageService.getHistory();
      expect(history.length, 1);
      expect(history.first.durationMinutes, 30);
      expect(history.first.targetDurationMinutes, 30);
    });
  });
}
