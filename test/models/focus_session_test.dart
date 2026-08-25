import 'package:flutter_test/flutter_test.dart';
import 'package:lock_in/models/focus_session.dart';

void main() {
  group('FocusSession Tests', () {
    test('creates FocusSession with correct default and explicit fields', () {
      final now = DateTime.now();
      final session = FocusSession(
        id: 'session-1',
        durationMinutes: 45,
        targetDurationMinutes: 45,
        dateTime: now,
        isWin: true,
        sessionType: SessionType.solo,
      );

      expect(session.id, 'session-1');
      expect(session.durationMinutes, 45);
      expect(session.targetDurationMinutes, 45);
      expect(session.dateTime, now);
      expect(session.isWin, true);
      expect(session.sessionType, SessionType.solo);
      expect(session.opponentName, isNull);
    });

    test(
      'serialization toMap, fromMap, toJson, fromJson handles battle session',
      () {
        final date = DateTime(2026, 8, 25, 10, 30);
        final session = FocusSession(
          id: 'session-battle-1',
          durationMinutes: 60,
          targetDurationMinutes: 60,
          dateTime: date,
          isWin: true,
          sessionType: SessionType.battle,
          opponentName: 'Marcus Vance',
          opponentScore: '60—45',
        );

        final map = session.toMap();
        expect(map['sessionType'], 'battle');
        expect(map['opponentName'], 'Marcus Vance');

        final fromMap = FocusSession.fromMap(map);
        expect(fromMap.id, session.id);
        expect(fromMap.durationMinutes, 60);
        expect(fromMap.targetDurationMinutes, 60);
        expect(fromMap.isWin, true);
        expect(fromMap.sessionType, SessionType.battle);
        expect(fromMap.opponentName, 'Marcus Vance');
        expect(fromMap.opponentScore, '60—45');

        final jsonStr = session.toJson();
        final fromJson = FocusSession.fromJson(jsonStr);
        expect(fromJson.id, session.id);
        expect(fromJson.sessionType, SessionType.battle);
      },
    );
  });
}
