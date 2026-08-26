import 'dart:async';
import '../models/battle_event.dart';
import '../models/battle_state.dart';
import 'battle_realtime_data_source.dart';
import 'battle_remote_data_source.dart';
import 'storage_service.dart';

/// Repository that mediates between UI state and local/remote/realtime data sources
class BattleRepository {
  final StorageService _storageService;
  final BattleRemoteDataSource _remoteDataSource;
  final BattleRealtimeDataSource _realtimeDataSource;

  BattleRepository({
    StorageService? storageService,
    BattleRemoteDataSource? remoteDataSource,
    BattleRealtimeDataSource? realtimeDataSource,
  })  : _storageService = storageService ?? StorageService(),
        _remoteDataSource = remoteDataSource ?? MockBattleRemoteDataSource(),
        _realtimeDataSource =
            realtimeDataSource ?? MockBattleRealtimeDataSource();

  Stream<BattleEvent> get eventStream => _realtimeDataSource.eventStream;
  Stream<BattleConnectionState> get connectionStateStream =>
      _realtimeDataSource.connectionStateStream;
  BattleConnectionState get connectionState =>
      _realtimeDataSource.connectionState;

  /// Retrieves or generates the anonymous installation ID
  Future<String> getAnonymousId() async {
    return _storageService.getOrCreateAnonymousId();
  }

  /// Create a new battle room as a guest host
  Future<BattleCreationResponse> createBattle({
    required int durationMinutes,
    required String displayName,
    String? avatar,
  }) async {
    final anonId = await getAnonymousId();
    final response = await _remoteDataSource.createBattle(
      durationMinutes: durationMinutes,
      displayName: displayName,
      anonymousId: anonId,
      avatar: avatar,
    );

    // Save initial state locally
    await _storageService.saveBattleSession(response.battle);
    return response;
  }

  /// Join an existing battle room with a 6-character room code
  Future<BattleJoinResponse> joinBattle({
    required String roomCode,
    required String displayName,
    String? avatar,
  }) async {
    final anonId = await getAnonymousId();
    final response = await _remoteDataSource.joinBattle(
      roomCode: roomCode,
      displayName: displayName,
      anonymousId: anonId,
      avatar: avatar,
    );

    // Save initial joined state locally
    await _storageService.saveBattleSession(response.battle);
    return response;
  }

  /// Connect to the real-time WebSocket channel for this battle
  Future<void> connectRealtime({
    required String battleId,
    required String participantToken,
    Uri? serverUri,
  }) async {
    final uri = serverUri ?? Uri.parse('http://localhost:8080');
    await _realtimeDataSource.connect(
      battleId: battleId,
      participantToken: participantToken,
      serverUri: uri,
    );
  }

  /// Send an event through the real-time channel
  Future<void> sendEvent(BattleEvent event) async {
    await _realtimeDataSource.sendEvent(event);
  }

  /// Disconnect real-time channel
  Future<void> disconnectRealtime() async {
    await _realtimeDataSource.disconnect();
  }

  /// Persist final battle results locally without requiring an account
  Future<void> persistBattleSession(BattleSessionModel battle) async {
    await _storageService.saveBattleSession(battle);
  }

  /// Get local history of guest focus battles
  Future<List<BattleSessionModel>> getLocalBattleSessions() async {
    return _storageService.getBattleSessions();
  }

  void dispose() {
    _realtimeDataSource.dispose();
  }
}
