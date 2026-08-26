import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/battle_event.dart';

/// Connection state of the real-time channel
enum BattleConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

/// Abstract contract for real-time battle communication
abstract class BattleRealtimeDataSource {
  Stream<BattleEvent> get eventStream;
  Stream<BattleConnectionState> get connectionStateStream;
  BattleConnectionState get connectionState;

  Future<void> connect({
    required String battleId,
    required String participantToken,
    required Uri serverUri,
  });

  Future<void> sendEvent(BattleEvent event);

  Future<void> disconnect();

  void dispose();
}

/// WebSocket implementation of the real-time battle channel
class WebSocketBattleRealtimeDataSource implements BattleRealtimeDataSource {
  WebSocket? _socket;
  final StreamController<BattleEvent> _eventController =
      StreamController<BattleEvent>.broadcast();
  final StreamController<BattleConnectionState> _stateController =
      StreamController<BattleConnectionState>.broadcast();

  BattleConnectionState _connectionState = BattleConnectionState.disconnected;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  String? _currentBattleId;
  String? _currentParticipantToken;
  Uri? _currentServerUri;

  @override
  Stream<BattleEvent> get eventStream => _eventController.stream;

  @override
  Stream<BattleConnectionState> get connectionStateStream =>
      _stateController.stream;

  @override
  BattleConnectionState get connectionState => _connectionState;

  void _updateState(BattleConnectionState newState) {
    if (_connectionState != newState) {
      _connectionState = newState;
      if (!_stateController.isClosed) {
        _stateController.add(_connectionState);
      }
    }
  }

  @override
  Future<void> connect({
    required String battleId,
    required String participantToken,
    required Uri serverUri,
  }) async {
    _currentBattleId = battleId;
    _currentParticipantToken = participantToken;
    _currentServerUri = serverUri;

    _updateState(BattleConnectionState.connecting);

    try {
      final wsUri = serverUri.replace(
        scheme: serverUri.scheme == 'https' ? 'wss' : 'ws',
        path: '/ws/battles/$battleId',
        queryParameters: {'token': participantToken},
      );

      _socket = await WebSocket.connect(
        wsUri.toString(),
      ).timeout(const Duration(seconds: 10));

      _reconnectAttempts = 0;
      _updateState(BattleConnectionState.connected);

      _socket!.listen(
        _onMessageReceived,
        onDone: _onSocketClosed,
        onError: _onSocketError,
        cancelOnError: false,
      );

      _startHeartbeat(battleId, participantToken);
    } catch (e) {
      _updateState(BattleConnectionState.failed);
      _scheduleReconnect();
    }
  }

  void _onMessageReceived(dynamic data) {
    try {
      final String text = data is String
          ? data
          : utf8.decode(data as List<int>);
      final event = BattleEvent.fromJson(text);
      if (!_eventController.isClosed) {
        _eventController.add(event);
      }
    } catch (_) {
      // Ignored malformed message
    }
  }

  void _onSocketClosed() {
    _heartbeatTimer?.cancel();
    if (_connectionState != BattleConnectionState.disconnected) {
      _updateState(BattleConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  void _onSocketError(dynamic error) {
    _heartbeatTimer?.cancel();
    _updateState(BattleConnectionState.failed);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _updateState(BattleConnectionState.failed);
      return;
    }

    _reconnectTimer?.cancel();
    _updateState(BattleConnectionState.reconnecting);
    _reconnectAttempts++;

    final backoffSeconds = 2 * _reconnectAttempts;
    _reconnectTimer = Timer(Duration(seconds: backoffSeconds), () {
      if (_currentBattleId != null &&
          _currentParticipantToken != null &&
          _currentServerUri != null) {
        connect(
          battleId: _currentBattleId!,
          participantToken: _currentParticipantToken!,
          serverUri: _currentServerUri!,
        );
      }
    });
  }

  void _startHeartbeat(String battleId, String participantId) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_connectionState == BattleConnectionState.connected) {
        sendEvent(
          BattleEvent.heartbeat(
            battleId: battleId,
            participantId: participantId,
          ),
        );
      }
    });
  }

  @override
  Future<void> sendEvent(BattleEvent event) async {
    if (_socket != null &&
        _socket!.readyState == WebSocket.open &&
        _connectionState == BattleConnectionState.connected) {
      _socket!.add(event.toJson());
    }
  }

  @override
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    _reconnectAttempts = 0;
    _currentBattleId = null;
    _currentParticipantToken = null;

    if (_socket != null) {
      await _socket!.close();
      _socket = null;
    }
    _updateState(BattleConnectionState.disconnected);
  }

  @override
  void dispose() {
    disconnect();
    _eventController.close();
    _stateController.close();
  }
}

/// Simulated mock real-time data source for local testing, offline simulation, and preview
class MockBattleRealtimeDataSource implements BattleRealtimeDataSource {
  final StreamController<BattleEvent> _eventController =
      StreamController<BattleEvent>.broadcast();
  final StreamController<BattleConnectionState> _stateController =
      StreamController<BattleConnectionState>.broadcast();

  BattleConnectionState _connectionState = BattleConnectionState.disconnected;

  @override
  Stream<BattleEvent> get eventStream => _eventController.stream;

  @override
  Stream<BattleConnectionState> get connectionStateStream =>
      _stateController.stream;

  @override
  BattleConnectionState get connectionState => _connectionState;

  @override
  Future<void> connect({
    required String battleId,
    required String participantToken,
    required Uri serverUri,
  }) async {
    _connectionState = BattleConnectionState.connected;
    _stateController.add(_connectionState);
  }

  @override
  Future<void> sendEvent(BattleEvent event) async {
    // Echo event back or dispatch to event stream
    _eventController.add(event);
  }

  void simulateRemoteEvent(BattleEvent event) {
    _eventController.add(event);
  }

  @override
  Future<void> disconnect() async {
    _connectionState = BattleConnectionState.disconnected;
    _stateController.add(_connectionState);
  }

  @override
  void dispose() {
    disconnect();
    _eventController.close();
    _stateController.close();
  }
}
