import 'package:flutter_test/flutter_test.dart';
import 'package:lock_in/models/battle_model.dart';

void main() {
  group('BattleModel Tests', () {
    test('creates BattleModel with correct default and explicit values', () {
      const battle = BattleModel(
        id: 'battle-123',
        opponentName: 'Alex Rivers',
        opponentInitials: 'AR',
        userMinutes: 120,
        opponentMinutes: 90,
        endsIn: 'ends in 2h',
        isActive: true,
      );

      expect(battle.id, 'battle-123');
      expect(battle.opponentName, 'Alex Rivers');
      expect(battle.opponentInitials, 'AR');
      expect(battle.userMinutes, 120);
      expect(battle.opponentMinutes, 90);
      expect(battle.endsIn, 'ends in 2h');
      expect(battle.isActive, true);
      expect(battle.isUserAhead, true);
      expect(battle.scoreComparison, '120—90');
    });

    test(
      'isUserAhead returns false when user minutes are lower than opponent',
      () {
        const battle = BattleModel(
          id: 'battle-456',
          opponentName: 'Elena Rostova',
          opponentInitials: 'ER',
          userMinutes: 50,
          opponentMinutes: 100,
          endsIn: 'ends in 4h',
        );

        expect(battle.isUserAhead, false);
        expect(battle.scoreComparison, '50—100');
      },
    );

    test('copyWith updates specified fields correctly', () {
      const original = BattleModel(
        id: 'b-1',
        opponentName: 'Sam',
        opponentInitials: 'S',
        userMinutes: 30,
        opponentMinutes: 40,
        endsIn: '1h',
        isActive: true,
      );

      final updated = original.copyWith(userMinutes: 50, isActive: false);

      expect(updated.id, 'b-1');
      expect(updated.userMinutes, 50);
      expect(updated.opponentMinutes, 40);
      expect(updated.isActive, false);
    });

    test(
      'serialization toMap, fromMap, toJson, fromJson works symmetrically',
      () {
        const battle = BattleModel(
          id: 'b-2',
          opponentName: 'Jordan',
          opponentInitials: 'J',
          userMinutes: 75,
          opponentMinutes: 60,
          endsIn: 'ends in 30m',
          isActive: true,
        );

        final map = battle.toMap();
        final fromMap = BattleModel.fromMap(map);

        expect(fromMap.id, battle.id);
        expect(fromMap.opponentName, battle.opponentName);
        expect(fromMap.opponentInitials, battle.opponentInitials);
        expect(fromMap.userMinutes, battle.userMinutes);
        expect(fromMap.opponentMinutes, battle.opponentMinutes);
        expect(fromMap.endsIn, battle.endsIn);
        expect(fromMap.isActive, battle.isActive);

        final jsonString = battle.toJson();
        final fromJson = BattleModel.fromJson(jsonString);

        expect(fromJson.id, battle.id);
        expect(fromJson.opponentName, battle.opponentName);
      },
    );

    test('handles default fallbacks in fromMap', () {
      final battle = BattleModel.fromMap({});
      expect(battle.id, '');
      expect(battle.opponentName, '');
      expect(battle.opponentInitials, '');
      expect(battle.userMinutes, 0);
      expect(battle.opponentMinutes, 0);
      expect(battle.endsIn, 'ends in 2h');
      expect(battle.isActive, true);
    });
  });
}
