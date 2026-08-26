import 'package:flutter_test/flutter_test.dart';
import 'package:lock_in/models/battle_state.dart';

void main() {
  group('BattleState Models Tests', () {
    test('BattleParticipant serialization and helpers', () {
      const participant = BattleParticipant(
        id: 'p1',
        displayName: 'Maya',
        status: ParticipantStatus.ready,
        isHost: true,
        focusedSeconds: 120,
      );

      expect(participant.isReady, isTrue);
      expect(participant.isActive, isFalse);

      final map = participant.toMap();
      final fromMap = BattleParticipant.fromMap(map);

      expect(fromMap.id, 'p1');
      expect(fromMap.displayName, 'Maya');
      expect(fromMap.status, ParticipantStatus.ready);
      expect(fromMap.isHost, isTrue);
      expect(fromMap.focusedSeconds, 120);

      final jsonStr = participant.toJson();
      final fromJson = BattleParticipant.fromJson(jsonStr);
      expect(fromJson.id, 'p1');
    });

    test('BattleSessionModel state machine & getters', () {
      const p1 = BattleParticipant(
        id: 'p1',
        displayName: 'Maya',
        status: ParticipantStatus.ready,
        isHost: true,
      );
      const p2 = BattleParticipant(
        id: 'p2',
        displayName: 'Sam',
        status: ParticipantStatus.ready,
        isHost: false,
      );

      final session = BattleSessionModel(
        id: 'b1',
        roomCode: 'K7XM4P',
        durationMinutes: 25,
        status: BattleStatus.waitingForReady,
        participants: const [p1, p2],
        createdAt: DateTime(2026, 8, 26, 10, 0),
      );

      expect(session.areBothReady, isTrue);
      expect(session.isWaitingForOpponent, isFalse);
      expect(session.host?.id, 'p1');
      expect(session.guest?.id, 'p2');
      expect(session.getOpponent('p1')?.id, 'p2');

      final jsonStr = session.toJson();
      final fromJson = BattleSessionModel.fromJson(jsonStr);

      expect(fromJson.id, 'b1');
      expect(fromJson.roomCode, 'K7XM4P');
      expect(fromJson.participants.length, 2);
      expect(fromJson.areBothReady, isTrue);
    });

    test('BattleResultModel victory calculations and serialization', () {
      const p1 = BattleParticipant(
        id: 'p1',
        displayName: 'Maya',
        status: ParticipantStatus.finished,
      );
      const p2 = BattleParticipant(
        id: 'p2',
        displayName: 'Sam',
        status: ParticipantStatus.forfeited,
      );

      final result = BattleResultModel(
        battleId: 'b1',
        roomCode: 'K7XM4P',
        winnerParticipantId: 'p1',
        isDraw: false,
        localParticipant: p1,
        opponentParticipant: p2,
        completedAt: DateTime.now(),
        isForfeit: true,
        forfeitParticipantId: 'p2',
      );

      expect(result.isLocalWinner, isTrue);
      expect(result.isOpponentWinner, isFalse);

      final map = result.toMap();
      final fromMap = BattleResultModel.fromMap(map);

      expect(fromMap.winnerParticipantId, 'p1');
      expect(fromMap.isForfeit, isTrue);
      expect(fromMap.forfeitParticipantId, 'p2');
    });
  });
}
