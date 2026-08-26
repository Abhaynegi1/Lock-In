import 'dart:convert';

/// Status of the entire battle session
enum BattleStatus {
  created,
  waitingForPlayer,
  waitingForReady,
  countdown,
  active,
  playerDisconnected,
  completed,
  cancelled;

  static BattleStatus fromString(String val) {
    return BattleStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => BattleStatus.created,
    );
  }
}

/// Status of an individual participant in the battle
enum ParticipantStatus {
  joined,
  ready,
  active,
  disconnected,
  finished,
  forfeited;

  static ParticipantStatus fromString(String val) {
    return ParticipantStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => ParticipantStatus.joined,
    );
  }
}

/// A participant in a battle session
class BattleParticipant {
  final String id;
  final String displayName;
  final String avatar;
  final ParticipantStatus status;
  final int focusedSeconds;
  final bool isHost;
  final DateTime? lastSeenAt;

  const BattleParticipant({
    required this.id,
    required this.displayName,
    this.avatar = 'assets/default_pfp/avatar-spark.svg',
    this.status = ParticipantStatus.joined,
    this.focusedSeconds = 0,
    this.isHost = false,
    this.lastSeenAt,
  });

  bool get isReady => status == ParticipantStatus.ready;
  bool get isActive => status == ParticipantStatus.active;
  bool get isDisconnected => status == ParticipantStatus.disconnected;
  bool get isFinished => status == ParticipantStatus.finished;
  bool get isForfeited => status == ParticipantStatus.forfeited;

  BattleParticipant copyWith({
    String? id,
    String? displayName,
    String? avatar,
    ParticipantStatus? status,
    int? focusedSeconds,
    bool? isHost,
    DateTime? lastSeenAt,
  }) {
    return BattleParticipant(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatar: avatar ?? this.avatar,
      status: status ?? this.status,
      focusedSeconds: focusedSeconds ?? this.focusedSeconds,
      isHost: isHost ?? this.isHost,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'avatar': avatar,
      'status': status.name,
      'focusedSeconds': focusedSeconds,
      'isHost': isHost,
      'lastSeenAt': lastSeenAt?.toIso8601String(),
    };
  }

  factory BattleParticipant.fromMap(Map<String, dynamic> map) {
    return BattleParticipant(
      id: map['id'] ?? '',
      displayName: map['displayName'] ?? 'Guest',
      avatar: map['avatar'] ?? 'assets/default_pfp/avatar-spark.svg',
      status: ParticipantStatus.fromString(map['status'] ?? 'joined'),
      focusedSeconds: map['focusedSeconds']?.toInt() ?? 0,
      isHost: map['isHost'] ?? false,
      lastSeenAt: map['lastSeenAt'] != null
          ? DateTime.tryParse(map['lastSeenAt'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory BattleParticipant.fromJson(String source) =>
      BattleParticipant.fromMap(json.decode(source));
}

/// Comprehensive model representing a real-time Battle Session
class BattleSessionModel {
  final String id;
  final String roomCode;
  final int durationMinutes;
  final BattleStatus status;
  final List<BattleParticipant> participants;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endsAt;
  final String? winnerId;
  final String? forfeitReason;
  final int gracePeriodSeconds;

  const BattleSessionModel({
    required this.id,
    required this.roomCode,
    required this.durationMinutes,
    this.status = BattleStatus.created,
    this.participants = const [],
    required this.createdAt,
    this.startedAt,
    this.endsAt,
    this.winnerId,
    this.forfeitReason,
    this.gracePeriodSeconds = 30,
  });

  bool get isWaitingForOpponent =>
      status == BattleStatus.created ||
      status == BattleStatus.waitingForPlayer ||
      participants.length < 2;

  bool get areBothReady =>
      participants.length == 2 && participants.every((p) => p.isReady);

  bool get isLive =>
      status == BattleStatus.active ||
      status == BattleStatus.playerDisconnected;

  bool get isEnded =>
      status == BattleStatus.completed || status == BattleStatus.cancelled;

  BattleParticipant? get host =>
      participants.where((p) => p.isHost).firstOrNull ??
      participants.firstOrNull;

  BattleParticipant? get guest =>
      participants.where((p) => !p.isHost).firstOrNull;

  BattleParticipant? findParticipant(String participantId) =>
      participants.where((p) => p.id == participantId).firstOrNull;

  BattleParticipant? getOpponent(String myParticipantId) =>
      participants.where((p) => p.id != myParticipantId).firstOrNull;

  BattleSessionModel copyWith({
    String? id,
    String? roomCode,
    int? durationMinutes,
    BattleStatus? status,
    List<BattleParticipant>? participants,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endsAt,
    String? winnerId,
    String? forfeitReason,
    int? gracePeriodSeconds,
  }) {
    return BattleSessionModel(
      id: id ?? this.id,
      roomCode: roomCode ?? this.roomCode,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endsAt: endsAt ?? this.endsAt,
      winnerId: winnerId ?? this.winnerId,
      forfeitReason: forfeitReason ?? this.forfeitReason,
      gracePeriodSeconds: gracePeriodSeconds ?? this.gracePeriodSeconds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomCode': roomCode,
      'durationMinutes': durationMinutes,
      'status': status.name,
      'participants': participants.map((p) => p.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'endsAt': endsAt?.toIso8601String(),
      'winnerId': winnerId,
      'forfeitReason': forfeitReason,
      'gracePeriodSeconds': gracePeriodSeconds,
    };
  }

  factory BattleSessionModel.fromMap(Map<String, dynamic> map) {
    return BattleSessionModel(
      id: map['id'] ?? '',
      roomCode: map['roomCode'] ?? '',
      durationMinutes: map['durationMinutes']?.toInt() ?? 25,
      status: BattleStatus.fromString(map['status'] ?? 'created'),
      participants: (map['participants'] as List<dynamic>? ?? [])
          .map((p) => BattleParticipant.fromMap(p as Map<String, dynamic>))
          .toList(),
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      startedAt: map['startedAt'] != null
          ? DateTime.tryParse(map['startedAt'])
          : null,
      endsAt: map['endsAt'] != null ? DateTime.tryParse(map['endsAt']) : null,
      winnerId: map['winnerId'],
      forfeitReason: map['forfeitReason'],
      gracePeriodSeconds: map['gracePeriodSeconds']?.toInt() ?? 30,
    );
  }

  String toJson() => json.encode(toMap());

  factory BattleSessionModel.fromJson(String source) =>
      BattleSessionModel.fromMap(json.decode(source));
}

/// Result summary of a completed or forfeited battle
class BattleResultModel {
  final String battleId;
  final String roomCode;
  final String? winnerParticipantId;
  final bool isDraw;
  final BattleParticipant localParticipant;
  final BattleParticipant opponentParticipant;
  final DateTime completedAt;
  final bool isForfeit;
  final String? forfeitParticipantId;

  const BattleResultModel({
    required this.battleId,
    required this.roomCode,
    this.winnerParticipantId,
    this.isDraw = false,
    required this.localParticipant,
    required this.opponentParticipant,
    required this.completedAt,
    this.isForfeit = false,
    this.forfeitParticipantId,
  });

  bool get isLocalWinner => winnerParticipantId == localParticipant.id;
  bool get isOpponentWinner => winnerParticipantId == opponentParticipant.id;

  Map<String, dynamic> toMap() {
    return {
      'battleId': battleId,
      'roomCode': roomCode,
      'winnerParticipantId': winnerParticipantId,
      'isDraw': isDraw,
      'localParticipant': localParticipant.toMap(),
      'opponentParticipant': opponentParticipant.toMap(),
      'completedAt': completedAt.toIso8601String(),
      'isForfeit': isForfeit,
      'forfeitParticipantId': forfeitParticipantId,
    };
  }

  factory BattleResultModel.fromMap(Map<String, dynamic> map) {
    return BattleResultModel(
      battleId: map['battleId'] ?? '',
      roomCode: map['roomCode'] ?? '',
      winnerParticipantId: map['winnerParticipantId'],
      isDraw: map['isDraw'] ?? false,
      localParticipant: BattleParticipant.fromMap(
          map['localParticipant'] as Map<String, dynamic>? ?? {}),
      opponentParticipant: BattleParticipant.fromMap(
          map['opponentParticipant'] as Map<String, dynamic>? ?? {}),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : DateTime.now(),
      isForfeit: map['isForfeit'] ?? false,
      forfeitParticipantId: map['forfeitParticipantId'],
    );
  }

  String toJson() => json.encode(toMap());

  factory BattleResultModel.fromJson(String source) =>
      BattleResultModel.fromMap(json.decode(source));
}
