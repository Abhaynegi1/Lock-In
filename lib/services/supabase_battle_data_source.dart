import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/battle_event.dart';
import '../models/battle_state.dart';
import 'battle_realtime_data_source.dart';
import 'battle_remote_data_source.dart';
import 'supabase_service.dart';

/// Production Supabase Realtime implementation for 1v1 Focus Battles
/// Operates 100% anonymously with zero login or user sign-in required.
class SupabaseBattleDataSource
    implements BattleRemoteDataSource, BattleRealtimeDataSource {
  final SupabaseClient _client;

  RealtimeChannel? _channel;
  String? _currentRoomCode;
  BattleSessionModel? _activeBattle;
  Completer<Map<String, dynamic>>? _pendingJoinCompleter;

  final StreamController<BattleEvent> _eventController =
      StreamController<BattleEvent>.broadcast();
  final StreamController<BattleConnectionState> _connectionStateController =
      StreamController<BattleConnectionState>.broadcast();

  BattleConnectionState _connectionState = BattleConnectionState.disconnected;

  SupabaseBattleDataSource({SupabaseClient? client})
    : _client = client ?? SupabaseService().client;

  @override
  Stream<BattleEvent> get eventStream => _eventController.stream;

  @override
  Stream<BattleConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  BattleConnectionState get connectionState => _connectionState;

  static String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = math.Random();
    return List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  void _updateConnectionState(BattleConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      if (!_connectionStateController.isClosed) {
        _connectionStateController.add(newState);
      }
    }
  }

  @override
  Future<BattleCreationResponse> createBattle({
    required int durationMinutes,
    required String displayName,
    required String anonymousId,
    String? avatar,
  }) async {
    await disconnect();

    final roomCode = _generateRoomCode();
    final battleId = const Uuid().v4();
    final participantId = const Uuid().v4();
    final participantToken = 'sb_token_${const Uuid().v4()}';

    final hostParticipant = BattleParticipant(
      id: participantId,
      displayName: displayName,
      avatar: avatar ?? 'assets/default_pfp/avatar-spark.svg',
      status: ParticipantStatus.joined,
      isHost: true,
    );

    final battle = BattleSessionModel(
      id: battleId,
      roomCode: roomCode,
      durationMinutes: durationMinutes,
      status: BattleStatus.waitingForPlayer,
      participants: [hostParticipant],
      createdAt: DateTime.now(),
    );

    _currentRoomCode = roomCode;
    _activeBattle = battle;

    // Join room channel and listen for events
    final channel = await _subscribeToRoomChannel(roomCode, isHost: true);

    // Track host presence on the channel so joining guests can discover immediately
    try {
      await channel.track({
        'isHost': true,
        'battleId': battleId,
        'roomCode': roomCode,
        'durationMinutes': durationMinutes,
        'host': hostParticipant.toMap(),
        'status': battle.status.name,
      });
      debugPrint('[BattleRealtime] Host presence tracked for room $roomCode');
    } catch (e) {
      debugPrint('[BattleRealtime] Presence track warning: $e');
    }

    return BattleCreationResponse(
      battleId: battleId,
      roomCode: roomCode,
      participantId: participantId,
      participantToken: participantToken,
      battle: battle,
    );
  }

  @override
  Future<BattleJoinResponse> joinBattle({
    required String roomCode,
    required String displayName,
    required String anonymousId,
    String? avatar,
  }) async {
    final code = roomCode.trim().toUpperCase();
    if (code.length != 6) {
      throw Exception('Invalid room code. Room code must be 6 characters.');
    }

    await disconnect();

    _updateConnectionState(BattleConnectionState.connecting);

    final participantId = const Uuid().v4();
    final participantToken = 'sb_token_${const Uuid().v4()}';
    _currentRoomCode = code;

    final roomInfoCompleter = Completer<Map<String, dynamic>>();
    _pendingJoinCompleter = roomInfoCompleter;

    // Connect to room channel
    final channel = await _subscribeToRoomChannel(code, isHost: false);

    // 1. Listen for Presence Sync (instant discovery if host is tracked)
    channel.onPresenceSync((_) {
      try {
        final presenceList = channel.presenceState();
        for (final p in presenceList) {
          for (final pr in p.presences) {
            if (pr.payload['isHost'] == true && !roomInfoCompleter.isCompleted) {
              debugPrint('[BattleRealtime] Host found via Presence Sync for $code');
              roomInfoCompleter.complete(Map<String, dynamic>.from(pr.payload));
              return;
            }
          }
        }
      } catch (e) {
        debugPrint('[BattleRealtime] Error checking presence state: $e');
      }
    });

    // 2. Listen for Broadcast ROOM_INFO
    final sub = _eventController.stream.listen((event) {
      if (event.type == BattleEventType.battleCreated ||
          event.type == BattleEventType.playerJoined ||
          event.payload.containsKey('roomInfo') ||
          event.payload['isHost'] == true) {
        if (!roomInfoCompleter.isCompleted) {
          debugPrint('[BattleRealtime] Host responded via Broadcast event for $code');
          roomInfoCompleter.complete(event.payload);
        }
      }
    });

    try {
      // Check if presence is already available right now
      final currentPresence = channel.presenceState();
      for (final p in currentPresence) {
        for (final pr in p.presences) {
          if (pr.payload['isHost'] == true && !roomInfoCompleter.isCompleted) {
            roomInfoCompleter.complete(Map<String, dynamic>.from(pr.payload));
            break;
          }
        }
      }

      // 3. Broadcast discovery query with retry (every 800ms up to 5 attempts)
      Map<String, dynamic>? roomPayload;
      for (var attempt = 0; attempt < 5; attempt++) {
        if (roomInfoCompleter.isCompleted) {
          roomPayload = await roomInfoCompleter.future;
          break;
        }

        debugPrint('[BattleRealtime] Guest sending query attempt ${attempt + 1} for $code');
        await channel.sendBroadcastMessage(
          event: 'battle_event',
          payload: {
            'event': 'ROOM_QUERY',
            'roomCode': code,
            'guestName': displayName,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );

        try {
          roomPayload = await roomInfoCompleter.future.timeout(
            const Duration(milliseconds: 1000),
          );
          break;
        } catch (_) {
          // Retry next attempt
        }
      }

      if (roomPayload == null) {
        throw Exception(
          'Room "$code" does not exist or host is offline. Please verify the code.',
        );
      }

      final battleData = roomPayload['battle'] is Map<String, dynamic>
          ? roomPayload['battle'] as Map<String, dynamic>
          : roomPayload;

      final battleId =
          roomPayload['battleId']?.toString() ??
          battleData['id']?.toString() ??
          const Uuid().v4();

      final durationMinutes =
          roomPayload['durationMinutes'] as int? ??
          battleData['durationMinutes'] as int? ??
          25;

      // Extract host participant
      BattleParticipant? hostParticipant;
      if (roomPayload['host'] is Map<String, dynamic>) {
        hostParticipant = BattleParticipant.fromMap(
          Map<String, dynamic>.from(roomPayload['host'] as Map),
        );
      } else if (battleData['participants'] is List &&
          (battleData['participants'] as List).isNotEmpty) {
        hostParticipant = BattleParticipant.fromMap(
          Map<String, dynamic>.from(battleData['participants'][0] as Map),
        );
      } else {
        hostParticipant = const BattleParticipant(
          id: 'host',
          displayName: 'Host',
          status: ParticipantStatus.joined,
          isHost: true,
        );
      }

      final guestParticipant = BattleParticipant(
        id: participantId,
        displayName: displayName,
        avatar: avatar ?? 'assets/default_pfp/avatar-spark.svg',
        status: ParticipantStatus.joined,
        isHost: false,
      );

      final battle = BattleSessionModel(
        id: battleId,
        roomCode: code,
        durationMinutes: durationMinutes,
        status: BattleStatus.waitingForReady,
        participants: [hostParticipant, guestParticipant],
        createdAt: DateTime.now(),
      );

      _activeBattle = battle;
      _updateConnectionState(BattleConnectionState.connected);

      return BattleJoinResponse(
        battleId: battleId,
        participantId: participantId,
        participantToken: participantToken,
        battle: battle,
      );
    } finally {
      _pendingJoinCompleter = null;
      await sub.cancel();
    }
  }

  Future<RealtimeChannel> _subscribeToRoomChannel(
    String roomCode, {
    required bool isHost,
  }) async {
    _updateConnectionState(BattleConnectionState.connecting);

    final channelName = 'battle_${roomCode.toUpperCase()}';
    final channel = _client.channel(
      channelName,
      opts: const RealtimeChannelConfig(self: false),
    );

    channel.onBroadcast(
      event: 'battle_event',
      callback: (payload) {
        _handleBroadcastMessage(payload, isHost: isHost);
      },
    );

    final subscribeCompleter = Completer<void>();
    channel.subscribe((status, [error]) {
      debugPrint('[BattleRealtime] Channel $channelName status: $status, error: $error');
      if (status == RealtimeSubscribeStatus.subscribed) {
        _updateConnectionState(BattleConnectionState.connected);
        if (!subscribeCompleter.isCompleted) {
          subscribeCompleter.complete();
        }
      } else if (status == RealtimeSubscribeStatus.closed ||
          status == RealtimeSubscribeStatus.channelError) {
        _updateConnectionState(BattleConnectionState.failed);
      }
    });

    try {
      await subscribeCompleter.future.timeout(const Duration(seconds: 12));
    } catch (e) {
      debugPrint('[BattleRealtime] Channel subscription timeout/warning for $channelName: $e');
    }

    _channel = channel;
    return channel;
  }

  void _handleBroadcastMessage(
    Map<String, dynamic> rawEnvelope, {
    required bool isHost,
  }) {
    // Supabase broadcast wraps payload as: {'event': 'battle_event', 'topic': '...', 'payload': { ... }}
    final Map<String, dynamic> data =
        rawEnvelope['payload'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(rawEnvelope['payload'] as Map)
            : rawEnvelope;

    final eventName = (data['event'] ?? rawEnvelope['event'] ?? '').toString();
    debugPrint('[BattleRealtime] Received broadcast eventName: "$eventName" (isHost: $isHost)');

    // 1. If host receives a query from a connecting guest, reply with room metadata
    if (isHost && eventName == 'ROOM_QUERY') {
      if (_activeBattle != null && _channel != null) {
        final host = _activeBattle!.participants.firstWhere(
          (p) => p.isHost,
          orElse: () => _activeBattle!.participants.first,
        );

        debugPrint('[BattleRealtime] Host replying with ROOM_INFO for ${_activeBattle!.roomCode}');
        _channel!.sendBroadcastMessage(
          event: 'battle_event',
          payload: {
            'event': 'ROOM_INFO',
            'roomInfo': true,
            'battleId': _activeBattle!.id,
            'roomCode': _activeBattle!.roomCode,
            'durationMinutes': _activeBattle!.durationMinutes,
            'host': host.toMap(),
            'status': _activeBattle!.status.name,
            'battle': _activeBattle!.toMap(),
          },
        );
      }
      return;
    }

    // 2. If guest receives ROOM_INFO, complete pending join immediately
    if (!isHost &&
        (eventName == 'ROOM_INFO' ||
            data['roomInfo'] == true ||
            data['isHost'] == true)) {
      debugPrint('[BattleRealtime] Guest received direct ROOM_INFO reply!');
      if (_pendingJoinCompleter != null && !_pendingJoinCompleter!.isCompleted) {
        _pendingJoinCompleter!.complete(data);
      }
    }

    // 3. Parse into standard BattleEvent and emit to repository/provider
    final battleEvent = BattleEvent.fromMap(data);
    if (!_eventController.isClosed) {
      _eventController.add(battleEvent);
    }
  }

  @override
  Future<BattleSessionModel> getBattleStatus({
    required String battleId,
    required String participantToken,
  }) async {
    if (_activeBattle != null) return _activeBattle!;
    return BattleSessionModel(
      id: battleId,
      roomCode: _currentRoomCode ?? '------',
      durationMinutes: 25,
      status: BattleStatus.active,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> connect({
    required String battleId,
    required String participantToken,
    required Uri serverUri,
  }) async {
    if (_channel != null) {
      _updateConnectionState(BattleConnectionState.connected);
      return;
    }

    if (_currentRoomCode != null) {
      await _subscribeToRoomChannel(_currentRoomCode!, isHost: false);
    }
  }

  @override
  Future<void> sendEvent(BattleEvent event) async {
    if (_channel != null) {
      final payload = event.toMap();
      debugPrint('[BattleRealtime] Sending broadcast event: ${event.type.toWireString()}');
      await _channel!.sendBroadcastMessage(
        event: 'battle_event',
        payload: payload,
      );
    }
  }

  @override
  Future<void> disconnect() async {
    if (_channel != null) {
      try {
        await _channel!.untrack();
        await _channel!.unsubscribe();
        await _client.removeChannel(_channel!);
      } catch (e) {
        debugPrint('[BattleRealtime] Error disconnecting channel: $e');
      }
      _channel = null;
    }
    _pendingJoinCompleter = null;
    _updateConnectionState(BattleConnectionState.disconnected);
  }

  @override
  void dispose() {
    disconnect();
    _eventController.close();
    _connectionStateController.close();
  }
}
