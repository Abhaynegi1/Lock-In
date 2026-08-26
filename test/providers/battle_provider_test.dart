import 'package:flutter_test/flutter_test.dart';
import 'package:lock_in/models/battle_event.dart';
import 'package:lock_in/models/battle_state.dart';
import 'package:lock_in/providers/battle_provider.dart';
import 'package:lock_in/services/battle_realtime_data_source.dart';
import 'package:lock_in/services/battle_remote_data_source.dart';
import 'package:lock_in/services/battle_repository.dart';
import 'package:lock_in/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BattleProvider Tests', () {
    late BattleProvider provider;
    late BattleRepository repository;
    late MockBattleRealtimeDataSource mockRealtime;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      mockRealtime = MockBattleRealtimeDataSource();
      repository = BattleRepository(
        storageService: storage,
        remoteDataSource: MockBattleRemoteDataSource(),
        realtimeDataSource: mockRealtime,
      );
      provider = BattleProvider(repository: repository, storageService: storage);
    });

    tearDown(() {
      provider.dispose();
    });

    test('creates battle and initializes host state properly', () async {
      final success = await provider.createBattle(
        durationMinutes: 25,
        displayName: 'Alice',
      );

      expect(success, isTrue);
      expect(provider.currentBattle, isNotNull);
      expect(provider.isHost, isTrue);
      expect(provider.currentBattle?.roomCode.length, 6);
      expect(provider.status, BattleStatus.waitingForPlayer);
    });

    test('toggles ready state and reacts to player events', () async {
      await provider.createBattle(
        durationMinutes: 25,
        displayName: 'Alice',
      );

      expect(provider.isLocalReady, isFalse);

      await provider.toggleReady();
      expect(provider.isLocalReady, isTrue);

      await provider.toggleReady();
      expect(provider.isLocalReady, isFalse);
    });

    test('forfeitBattle emits forfeit event and marks battle completed with loss', () async {
      await provider.createBattle(
        durationMinutes: 25,
        displayName: 'Alice',
      );

      await provider.forfeitBattle(reason: 'Left application');

      expect(provider.status, BattleStatus.completed);
      expect(provider.lastResult, isNotNull);
      expect(provider.lastResult?.isForfeit, isTrue);
    });

    test('recovers server-authoritative timer on sync', () async {
      await provider.createBattle(
        durationMinutes: 25,
        displayName: 'Alice',
      );

      // Simulate remote BATTLE_STARTED event
      final now = DateTime.now();
      mockRealtime.simulateRemoteEvent(BattleEvent(
        type: BattleEventType.battleStarted,
        battleId: provider.currentBattle!.id,
        timestamp: now,
        payload: {
          'startedAt': now.toIso8601String(),
          'durationSeconds': 1500,
        },
      ));

      // Wait a microtask for event loop
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(provider.status, BattleStatus.active);
      expect(provider.totalDurationSeconds, 1500);
      expect(provider.secondsRemaining, greaterThan(1400));
    });
  });
}
