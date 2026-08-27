import 'package:flutter_test/flutter_test.dart';
import 'package:lock_in/services/battle_realtime_data_source.dart';
import 'package:lock_in/services/battle_remote_data_source.dart';
import 'package:lock_in/services/battle_repository.dart';
import 'package:lock_in/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BattleRepository Tests', () {
    late BattleRepository repository;
    late StorageService storageService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      storageService = StorageService();
      repository = BattleRepository(
        storageService: storageService,
        remoteDataSource: MockBattleRemoteDataSource(),
        realtimeDataSource: MockBattleRealtimeDataSource(),
      );
    });

    test(
      'retrieves anonymous installation ID and preserves across calls',
      () async {
        final id1 = await repository.getAnonymousId();
        expect(id1.isNotEmpty, isTrue);

        final id2 = await repository.getAnonymousId();
        expect(id1, id2);
      },
    );

    test('creates battle and persists initial record locally', () async {
      final response = await repository.createBattle(
        durationMinutes: 25,
        displayName: 'HostPlayer',
      );

      expect(response.battleId.isNotEmpty, isTrue);
      expect(response.roomCode.length, 6);
      expect(response.participantToken.isNotEmpty, isTrue);

      final localBattles = await repository.getLocalBattleSessions();
      expect(localBattles.length, 1);
      expect(localBattles.first.id, response.battleId);
      expect(localBattles.first.roomCode, response.roomCode);
    });

    test('joins battle and updates local persistence', () async {
      final createResp = await repository.createBattle(
        durationMinutes: 45,
        displayName: 'HostPlayer',
      );

      final joinResp = await repository.joinBattle(
        roomCode: createResp.roomCode,
        displayName: 'GuestPlayer',
      );

      expect(joinResp.battleId, createResp.battleId);
      expect(joinResp.battle.participants.length, 2);

      final localBattles = await repository.getLocalBattleSessions();
      expect(localBattles.any((b) => b.id == createResp.battleId), isTrue);
    });

    test('rejects non-existent room code with descriptive error', () async {
      expect(
        () => repository.joinBattle(
          roomCode: 'ABCDEF',
          displayName: 'GuestPlayer',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects room codes of invalid length', () async {
      expect(
        () => repository.joinBattle(
          roomCode: 'KJ67',
          displayName: 'GuestPlayer',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('rejects joining when room is already full (1v1)', () async {
      final createResp = await repository.createBattle(
        durationMinutes: 25,
        displayName: 'HostPlayer',
      );

      // First player joins (fills the room to 2)
      await repository.joinBattle(
        roomCode: createResp.roomCode,
        displayName: 'Player2',
      );

      // Third player attempts to join
      expect(
        () => repository.joinBattle(
          roomCode: createResp.roomCode,
          displayName: 'Player3',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
