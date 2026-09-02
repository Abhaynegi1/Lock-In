import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../models/battle_event.dart';
import '../models/battle_state.dart';
import 'battle_realtime_data_source.dart';
import 'battle_remote_data_source.dart';

/// Dedicated Node.js WebSocket Data Source for 1v1 Focus Battles
/// Connects to the Lock-In Battle server (local or hosted on Render).
class WebSocketBattleDataSource
    implements BattleRemoteDataSource, BattleRealtimeDataSource {
  /// Production live WebSocket endpoint from AppConfig
  static String get productionServerUrl => AppConfig.battleServerUrl;

  /// Currently active server URL (defaults to production endpoint)
  static String activeServerUrl = AppConfig.battleServerUrl;

  WebSocket? _socket;
  StreamSubscription? _socketSubscription;

  BattleSessionModel? _activeBattle;
  String? _localParticipantId;

  final StreamController<BattleEvent> _eventController =
      StreamController<BattleEvent>.broadcast();
  final StreamController<BattleConnectionState> _connectionStateController =
      StreamController<BattleConnectionState>.broadcast();

  BattleConnectionState _connectionState = BattleConnectionState.disconnected;

  Completer<Map<String, dynamic>>? _pendingCreationCompleter;
  Completer<Map<String, dynamic>>? _pendingJoinCompleter;

  @override
  Stream<BattleEvent> get eventStream => _eventController.stream;

  @override
  Stream<BattleConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  BattleConnectionState get connectionState => _connectionState;

  void _updateConnectionState(BattleConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      if (!_connectionStateController.isClosed) {
        _connectionStateController.add(newState);
      }
    }
  }

  /// Pre-warm the battle server in the background (e.g. when opening BattlesScreen)
  static Future<void> warmUpServer() async {
    try {
      final wsUri = Uri.parse(activeServerUrl);
      final scheme = wsUri.scheme == 'wss' ? 'https' : 'http';
      final httpUri = wsUri.replace(
        scheme: scheme,
        path: '/health',
      );
      debugPrint('[BattleWS] Pre-warming battle server at $httpUri ...');
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final request = await client.getUrl(httpUri);
      request.headers.set(HttpHeaders.hostHeader, httpUri.host);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json, */*');
      request.headers.set(HttpHeaders.userAgentHeader, 'LockIn-Client/1.0');
      final response = await request.close();
      await response.drain();
      client.close();
      debugPrint('[BattleWS] Pre-warm response code: ${response.statusCode}');
    } catch (e) {
      debugPrint('[BattleWS] Pre-warm ping ignored: $e');
    }
  }

  Future<void> _ensureConnected() async {
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      return;
    }

    _updateConnectionState(BattleConnectionState.connecting);

    final candidateUrls = <String>{
      activeServerUrl,
      productionServerUrl,
    }.toList();

    Object? lastError;

    for (final url in candidateUrls) {
      try {
        debugPrint('[BattleWS] Attempting connection to $url ...');
        // ignore: close_sinks
        final socket = await WebSocket.connect(url).timeout(
          const Duration(seconds: 20),
        );
        _socket = socket;
        activeServerUrl = url;
        debugPrint('[BattleWS] Connected successfully to $url!');
        break;
      } catch (err) {
        lastError = err;
        debugPrint('[BattleWS] Connection to $url failed: $err');
      }
    }

    if (_socket == null || _socket!.readyState != WebSocket.open) {
      _updateConnectionState(BattleConnectionState.failed);
      final isTimeout = lastError is TimeoutException ||
          (lastError != null &&
              (lastError.toString().contains('TimeoutException') ||
                  lastError.toString().contains('Future not completed')));
      if (isTimeout) {
        throw Exception(
          'Server is waking up. Please tap again in a moment.',
        );
      }
      throw Exception(
        'Could not connect to Battle Server. Please check your internet connection.',
      );
    }

    _updateConnectionState(BattleConnectionState.connected);
    debugPrint('[BattleWS] Connected successfully!');

    _socketSubscription = _socket!.listen(
      _handleIncomingRawMessage,
      onError: (err) {
        debugPrint('[BattleWS] Socket error: $err');
        _updateConnectionState(BattleConnectionState.failed);
      },
      onDone: () {
        debugPrint('[BattleWS] Socket closed by server');
        _updateConnectionState(BattleConnectionState.disconnected);
      },
    );
  }

  void _sendJson(Map<String, dynamic> data) {
    if (_socket != null && _socket!.readyState == WebSocket.open) {
      _socket!.add(jsonEncode(data));
    } else {
      debugPrint('[BattleWS] Cannot send message: socket not open');
    }
  }

  void _handleIncomingRawMessage(dynamic raw) {
    try {
      final text = raw.toString();
      final Map<String, dynamic> data = jsonDecode(text);
      final type = (data['type'] ?? '').toString();

      debugPrint('[BattleWS] Incoming message: $type');

      switch (type) {
        case 'ROOM_CREATED':
          if (_pendingCreationCompleter != null &&
              !_pendingCreationCompleter!.isCompleted) {
            _pendingCreationCompleter!.complete(data);
          }
          break;

        case 'ROOM_JOINED':
          if (_pendingJoinCompleter != null &&
              !_pendingJoinCompleter!.isCompleted) {
            _pendingJoinCompleter!.complete(data);
          }
          break;

        case 'ERROR':
          final msg = data['message'] ?? 'An error occurred on battle server';
          if (_pendingJoinCompleter != null &&
              !_pendingJoinCompleter!.isCompleted) {
            _pendingJoinCompleter!.completeError(Exception(msg));
          }
          if (_pendingCreationCompleter != null &&
              !_pendingCreationCompleter!.isCompleted) {
            _pendingCreationCompleter!.completeError(Exception(msg));
          }
          break;

        case 'PLAYER_JOINED':
          _eventController.add(
            BattleEvent(
              type: BattleEventType.playerJoined,
              battleId: _activeBattle?.id ?? '',
              timestamp: DateTime.now(),
              payload: data,
            ),
          );
          break;

        case 'PLAYER_READY':
          _eventController.add(
            BattleEvent(
              type: BattleEventType.playerReady,
              battleId: _activeBattle?.id ?? '',
              timestamp: DateTime.now(),
              payload: data,
            ),
          );
          break;

        case 'PLAYER_UNREADY':
          _eventController.add(
            BattleEvent(
              type: BattleEventType.playerUnready,
              battleId: _activeBattle?.id ?? '',
              timestamp: DateTime.now(),
              payload: data,
            ),
          );
          break;

        case 'BATTLE_STARTED':
          _eventController.add(
            BattleEvent(
              type: BattleEventType.battleStarted,
              battleId: _activeBattle?.id ?? '',
              timestamp: DateTime.now().toUtc(),
              payload: data,
            ),
          );
          break;

        case 'BATTLE_EXTENDED':
          _eventController.add(
            BattleEvent(
              type: BattleEventType.battleExtended,
              battleId: _activeBattle?.id ?? '',
              timestamp: DateTime.now(),
              payload: data,
            ),
          );
          break;

        case 'PROGRESS_UPDATE':
          _eventController.add(
            BattleEvent(
              type: BattleEventType.heartbeat,
              battleId: _activeBattle?.id ?? '',
              timestamp: DateTime.now(),
              payload: data,
            ),
          );
          break;

        case 'PLAYER_FORFEITED':
          _eventController.add(
            BattleEvent(
              type: BattleEventType.playerForfeited,
              battleId: _activeBattle?.id ?? '',
              timestamp: DateTime.now(),
              payload: data,
            ),
          );
          break;

        case 'PLAYER_FINISHED':
          _eventController.add(
            BattleEvent(
              type: BattleEventType.battleFinished,
              battleId: _activeBattle?.id ?? '',
              timestamp: DateTime.now(),
              payload: data,
            ),
          );
          break;

        case 'PLAYER_LEFT':
          _eventController.add(
            BattleEvent(
              type: BattleEventType.playerLeft,
              battleId: _activeBattle?.id ?? '',
              timestamp: DateTime.now(),
              payload: data,
            ),
          );
          break;

        case 'BATTLE_CANCELLED':
          _eventController.add(
            BattleEvent(
              type: BattleEventType.battleCancelled,
              battleId: _activeBattle?.id ?? '',
              timestamp: DateTime.now(),
              payload: data,
            ),
          );
          break;
      }
    } catch (e) {
      debugPrint('[BattleWS] Error handling message: $e');
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
    await _ensureConnected();

    _pendingCreationCompleter = Completer<Map<String, dynamic>>();

    _sendJson({
      'type': 'CREATE_ROOM',
      'durationMinutes': durationMinutes,
      'displayName': displayName,
      'avatar': avatar ?? 'assets/default_pfp/avatar-spark.svg',
    });

    try {
      final res = await _pendingCreationCompleter!.future.timeout(
        const Duration(seconds: 8),
      );

      final battleMap = Map<String, dynamic>.from(res['battle'] as Map);
      final battle = BattleSessionModel.fromMap(battleMap);

      _activeBattle = battle;
      _localParticipantId = res['participantId'].toString();

      return BattleCreationResponse(
        battleId: res['battleId'].toString(),
        roomCode: res['roomCode'].toString(),
        participantId: res['participantId'].toString(),
        participantToken: res['participantToken'].toString(),
        battle: battle,
      );
    } finally {
      _pendingCreationCompleter = null;
    }
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
    await _ensureConnected();

    _pendingJoinCompleter = Completer<Map<String, dynamic>>();

    _sendJson({
      'type': 'JOIN_ROOM',
      'roomCode': code,
      'displayName': displayName,
      'avatar': avatar ?? 'assets/default_pfp/avatar-spark.svg',
    });

    try {
      final res = await _pendingJoinCompleter!.future.timeout(
        const Duration(seconds: 8),
      );

      final battleMap = Map<String, dynamic>.from(res['battle'] as Map);
      final battle = BattleSessionModel.fromMap(battleMap);

      _activeBattle = battle;
      _localParticipantId = res['participantId'].toString();

      return BattleJoinResponse(
        battleId: res['battleId'].toString(),
        participantId: res['participantId'].toString(),
        participantToken: res['participantToken'].toString(),
        battle: battle,
      );
    } finally {
      _pendingJoinCompleter = null;
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
      roomCode: '------',
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
    await _ensureConnected();
  }

  @override
  Future<void> sendEvent(BattleEvent event) async {
    switch (event.type) {
      case BattleEventType.playerReady:
        _sendJson({
          'type': 'PLAYER_READY',
          'participantId': _localParticipantId,
        });
        break;

      case BattleEventType.playerUnready:
        _sendJson({
          'type': 'PLAYER_UNREADY',
          'participantId': _localParticipantId,
        });
        break;

      case BattleEventType.battleStarted:
        _sendJson({
          'type': 'START_BATTLE',
        });
        break;

      case BattleEventType.battleExtended:
        _sendJson({
          'type': 'EXTEND_BATTLE',
          'participantId': _localParticipantId,
          ...event.payload,
        });
        break;

      case BattleEventType.heartbeat:
        _sendJson({
          'type': 'PROGRESS_UPDATE',
          'participantId': _localParticipantId,
          ...event.payload,
        });
        break;

      case BattleEventType.playerForfeited:
        _sendJson({
          'type': 'PLAYER_FORFEIT',
          'participantId': _localParticipantId,
        });
        break;

      case BattleEventType.battleFinished:
        _sendJson({
          'type': 'PLAYER_FINISH',
          'participantId': _localParticipantId,
        });
        break;

      case BattleEventType.playerLeft:
      case BattleEventType.battleCancelled:
        _sendJson({
          'type': 'LEAVE_ROOM',
          'participantId': _localParticipantId,
        });
        break;

      default:
        break;
    }
  }

  @override
  Future<void> disconnect() async {
    if (_socket != null) {
      try {
        if (_localParticipantId != null) {
          _sendJson({
            'type': 'LEAVE_ROOM',
            'participantId': _localParticipantId,
          });
        }
        await _socketSubscription?.cancel();
        await _socket!.close();
      } catch (e) {
        debugPrint('[BattleWS] Error during disconnect: $e');
      }
      _socket = null;
      _socketSubscription = null;
    }
    _pendingCreationCompleter = null;
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
