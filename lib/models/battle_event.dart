import 'dart:convert';

/// Types of real-time WebSocket events sent between server and clients
enum BattleEventType {
  battleCreated,
  playerJoined,
  playerLeft,
  playerReady,
  playerUnready,
  battleStarting,
  battleStarted,
  playerForfeited,
  playerFinished,
  playerDisconnected,
  playerReconnected,
  battleFinished,
  battleCancelled,
  heartbeat,
  error;

  static BattleEventType fromString(String val) {
    // Handle both UPPER_SNAKE_CASE (e.g. BATTLE_STARTED) and camelCase (e.g. battleStarted)
    final normalized = val.toLowerCase().replaceAll('_', '');
    return BattleEventType.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => BattleEventType.error,
    );
  }

  String toWireString() {
    switch (this) {
      case BattleEventType.battleCreated:
        return 'BATTLE_CREATED';
      case BattleEventType.playerJoined:
        return 'PLAYER_JOINED';
      case BattleEventType.playerLeft:
        return 'PLAYER_LEFT';
      case BattleEventType.playerReady:
        return 'PLAYER_READY';
      case BattleEventType.playerUnready:
        return 'PLAYER_UNREADY';
      case BattleEventType.battleStarting:
        return 'BATTLE_STARTING';
      case BattleEventType.battleStarted:
        return 'BATTLE_STARTED';
      case BattleEventType.playerForfeited:
        return 'PLAYER_FORFEITED';
      case BattleEventType.playerFinished:
        return 'PLAYER_FINISHED';
      case BattleEventType.playerDisconnected:
        return 'PLAYER_DISCONNECTED';
      case BattleEventType.playerReconnected:
        return 'PLAYER_RECONNECTED';
      case BattleEventType.battleFinished:
        return 'BATTLE_FINISHED';
      case BattleEventType.battleCancelled:
        return 'BATTLE_CANCELLED';
      case BattleEventType.heartbeat:
        return 'HEARTBEAT';
      case BattleEventType.error:
        return 'ERROR';
    }
  }
}

/// Strongly typed envelope for all real-time Battle WebSocket communication
class BattleEvent {
  final BattleEventType type;
  final String battleId;
  final DateTime timestamp;
  final Map<String, dynamic> payload;

  const BattleEvent({
    required this.type,
    required this.battleId,
    required this.timestamp,
    this.payload = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'event': type.toWireString(),
      'battleId': battleId,
      'timestamp': timestamp.toIso8601String(),
      'payload': payload,
    };
  }

  factory BattleEvent.fromMap(Map<String, dynamic> map) {
    final eventStr = map['event'] ?? map['type'] ?? 'ERROR';
    final payloadData = map['payload'] is Map<String, dynamic>
        ? map['payload'] as Map<String, dynamic>
        : (Map<String, dynamic>.from(map)..remove('event')..remove('type')..remove('battleId')..remove('timestamp'));

    return BattleEvent(
      type: BattleEventType.fromString(eventStr.toString()),
      battleId: map['battleId']?.toString() ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      payload: payloadData,
    );
  }

  String toJson() => json.encode(toMap());

  factory BattleEvent.fromJson(String source) =>
      BattleEvent.fromMap(json.decode(source));

  // Convenience factories for client-dispatched events
  factory BattleEvent.playerReady({
    required String battleId,
    required String participantId,
  }) {
    return BattleEvent(
      type: BattleEventType.playerReady,
      battleId: battleId,
      timestamp: DateTime.now(),
      payload: {'participantId': participantId},
    );
  }

  factory BattleEvent.playerUnready({
    required String battleId,
    required String participantId,
  }) {
    return BattleEvent(
      type: BattleEventType.playerUnready,
      battleId: battleId,
      timestamp: DateTime.now(),
      payload: {'participantId': participantId},
    );
  }

  factory BattleEvent.playerForfeited({
    required String battleId,
    required String participantId,
    String? reason,
  }) {
    return BattleEvent(
      type: BattleEventType.playerForfeited,
      battleId: battleId,
      timestamp: DateTime.now(),
      payload: {
        'participantId': participantId,
        'reason': ?reason,
      },
    );
  }

  factory BattleEvent.playerFinished({
    required String battleId,
    required String participantId,
    required int focusedSeconds,
  }) {
    return BattleEvent(
      type: BattleEventType.playerFinished,
      battleId: battleId,
      timestamp: DateTime.now(),
      payload: {
        'participantId': participantId,
        'focusedSeconds': focusedSeconds,
      },
    );
  }

  factory BattleEvent.heartbeat({
    required String battleId,
    required String participantId,
  }) {
    return BattleEvent(
      type: BattleEventType.heartbeat,
      battleId: battleId,
      timestamp: DateTime.now(),
      payload: {'participantId': participantId},
    );
  }
}
