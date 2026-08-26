import 'package:flutter_test/flutter_test.dart';
import 'package:lock_in/models/battle_event.dart';

void main() {
  group('BattleEvent Tests', () {
    test('serializes and deserializes PLAYER_READY event', () {
      final event = BattleEvent.playerReady(
        battleId: 'battle_123',
        participantId: 'p_1',
      );

      expect(event.type, BattleEventType.playerReady);
      expect(event.type.toWireString(), 'PLAYER_READY');

      final jsonStr = event.toJson();
      final decoded = BattleEvent.fromJson(jsonStr);

      expect(decoded.type, BattleEventType.playerReady);
      expect(decoded.battleId, 'battle_123');
      expect(decoded.payload['participantId'], 'p_1');
    });

    test('serializes and deserializes PLAYER_FORFEITED event', () {
      final event = BattleEvent.playerForfeited(
        battleId: 'battle_123',
        participantId: 'p_2',
        reason: 'Left application',
      );

      expect(event.type, BattleEventType.playerForfeited);
      expect(event.type.toWireString(), 'PLAYER_FORFEITED');

      final map = event.toMap();
      final decoded = BattleEvent.fromMap(map);

      expect(decoded.type, BattleEventType.playerForfeited);
      expect(decoded.payload['reason'], 'Left application');
    });

    test('parses incoming wire string variants', () {
      expect(
        BattleEventType.fromString('BATTLE_STARTED'),
        BattleEventType.battleStarted,
      );
      expect(
        BattleEventType.fromString('player_disconnected'),
        BattleEventType.playerDisconnected,
      );
      expect(BattleEventType.fromString('unknown_type'), BattleEventType.error);
    });
  });
}
