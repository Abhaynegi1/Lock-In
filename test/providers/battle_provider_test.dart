import 'package:flutter_test/flutter_test.dart';
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
    late MockBattleRemoteDataSource mockRemote;
    late MockBattleRealtimeDataSource mockRealtime;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final storage = StorageService();
      mockRemote = MockBattleRemoteDataSource();
      mockRealtime = MockBattleRealtimeDataSource();
      repository = BattleRepository(
        storageService: storage,
        remoteDataSource: mockRemote,
        realtimeDataSource: mockRealtime,
      );
      provider = BattleProvider(
        repository: repository,
        storageService: storage,
      );
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
      await provider.createBattle(durationMinutes: 25, displayName: 'Alice');

      expect(provider.isLocalReady, isFalse);

      await provider.toggleReady();
      expect(provider.isLocalReady, isTrue);

      await provider.toggleReady();
      expect(provider.isLocalReady, isFalse);
    });

    test(
      'forfeitBattle emits forfeit event and marks battle completed with loss',
      () async {
        await provider.createBattle(durationMinutes: 25, displayName: 'Alice');

        await provider.forfeitBattle(reason: 'Left application');

        expect(provider.status, BattleStatus.completed);
        expect(provider.lastResult, isNotNull);
        expect(provider.lastResult?.isForfeit, isTrue);
      },
    );

    test('joins existing battle room successfully', () async {
      final createSuccess = await provider.createBattle(
        durationMinutes: 25,
        displayName: 'Alice',
      );
      expect(createSuccess, isTrue);
      final roomCode = provider.currentBattle!.roomCode;

      // Create a second provider instance representing guest player
      final guestStorage = StorageService();
      final guestProvider = BattleProvider(
        repository: BattleRepository(
          storageService: guestStorage,
          remoteDataSource: mockRemote, // share mock datasource
          realtimeDataSource: mockRealtime,
        ),
        storageService: guestStorage,
      );

      final joinSuccess = await guestProvider.joinBattle(
        roomCode: roomCode,
        displayName: 'Bob',
      );

      expect(joinSuccess, isTrue);
      expect(guestProvider.currentBattle, isNotNull);
      expect(guestProvider.currentBattle?.participants.length, 2);
      expect(guestProvider.isHost, isFalse);
      expect(guestProvider.errorMessage, isNull);

      guestProvider.dispose();
    });

    test(
      'fails to join non-existent room and sets descriptive error message',
      () async {
        final success = await provider.joinBattle(
          roomCode: 'NONEX9',
          displayName: 'Bob',
        );

        expect(success, isFalse);
        expect(provider.currentBattle, isNull);
        expect(provider.errorMessage, contains('does not exist'));
      },
    );
  });
}
