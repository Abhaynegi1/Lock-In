import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import '../models/battle_state.dart';

/// Response payload when creating a battle
class BattleCreationResponse {
  final String battleId;
  final String roomCode;
  final String participantId;
  final String participantToken;
  final BattleSessionModel battle;

  const BattleCreationResponse({
    required this.battleId,
    required this.roomCode,
    required this.participantId,
    required this.participantToken,
    required this.battle,
  });

  factory BattleCreationResponse.fromMap(Map<String, dynamic> map) {
    return BattleCreationResponse(
      battleId: map['battleId'] ?? '',
      roomCode: map['roomCode'] ?? '',
      participantId: map['participantId'] ?? '',
      participantToken: map['participantToken'] ?? '',
      battle: BattleSessionModel.fromMap(
        map['battle'] is Map<String, dynamic> ? map['battle'] : map,
      ),
    );
  }
}

/// Response payload when joining a battle
class BattleJoinResponse {
  final String battleId;
  final String participantId;
  final String participantToken;
  final BattleSessionModel battle;

  const BattleJoinResponse({
    required this.battleId,
    required this.participantId,
    required this.participantToken,
    required this.battle,
  });

  factory BattleJoinResponse.fromMap(Map<String, dynamic> map) {
    return BattleJoinResponse(
      battleId: map['battleId'] ?? '',
      participantId: map['participantId'] ?? '',
      participantToken: map['participantToken'] ?? '',
      battle: BattleSessionModel.fromMap(
        map['battle'] is Map<String, dynamic> ? map['battle'] : map,
      ),
    );
  }
}

/// Abstract contract for remote HTTP/REST battle endpoints
abstract class BattleRemoteDataSource {
  Future<BattleCreationResponse> createBattle({
    required int durationMinutes,
    required String displayName,
    required String anonymousId,
    String? avatar,
  });

  Future<BattleJoinResponse> joinBattle({
    required String roomCode,
    required String displayName,
    required String anonymousId,
    String? avatar,
  });

  Future<BattleSessionModel> getBattleStatus({
    required String battleId,
    required String participantToken,
  });
}

/// Production HTTP REST implementation of BattleRemoteDataSource
class HttpBattleRemoteDataSource implements BattleRemoteDataSource {
  final Uri baseServerUri;
  final HttpClient _client = HttpClient();

  HttpBattleRemoteDataSource({required this.baseServerUri});

  @override
  Future<BattleCreationResponse> createBattle({
    required int durationMinutes,
    required String displayName,
    required String anonymousId,
    String? avatar,
  }) async {
    final uri = baseServerUri.replace(path: '/api/v1/battles');
    final request = await _client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.add(
      utf8.encode(
        json.encode({
          'durationMinutes': durationMinutes,
          'displayName': displayName,
          'anonymousId': anonymousId,
          'avatar': ?avatar,
        }),
      ),
    );

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final map = json.decode(responseBody) as Map<String, dynamic>;
      return BattleCreationResponse.fromMap(map);
    } else {
      throw HttpException(
        'Failed to create battle: ${response.statusCode} $responseBody',
        uri: uri,
      );
    }
  }

  @override
  Future<BattleJoinResponse> joinBattle({
    required String roomCode,
    required String displayName,
    required String anonymousId,
    String? avatar,
  }) async {
    final uri = baseServerUri.replace(path: '/api/v1/battles/join');
    final request = await _client.postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.add(
      utf8.encode(
        json.encode({
          'roomCode': roomCode.trim().toUpperCase(),
          'displayName': displayName,
          'anonymousId': anonymousId,
          'avatar': ?avatar,
        }),
      ),
    );

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final map = json.decode(responseBody) as Map<String, dynamic>;
      return BattleJoinResponse.fromMap(map);
    } else {
      throw HttpException(
        'Failed to join battle: ${response.statusCode} $responseBody',
        uri: uri,
      );
    }
  }

  @override
  Future<BattleSessionModel> getBattleStatus({
    required String battleId,
    required String participantToken,
  }) async {
    final uri = baseServerUri.replace(path: '/api/v1/battles/$battleId');
    final request = await _client.getUrl(uri);
    request.headers.add('Authorization', 'Bearer $participantToken');

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final map = json.decode(responseBody) as Map<String, dynamic>;
      return BattleSessionModel.fromMap(map);
    } else {
      throw HttpException(
        'Failed to get battle status: ${response.statusCode} $responseBody',
        uri: uri,
      );
    }
  }
}

/// Simulated mock REST implementation for development and testing
class MockBattleRemoteDataSource implements BattleRemoteDataSource {
  final Map<String, BattleSessionModel> _mockStore = {};

  static String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = math.Random();
    return List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  @override
  Future<BattleCreationResponse> createBattle({
    required int durationMinutes,
    required String displayName,
    required String anonymousId,
    String? avatar,
  }) async {
    final battleId = const Uuid().v4();
    final participantId = const Uuid().v4();
    final roomCode = _generateRoomCode();
    final participantToken = 'mock_token_${const Uuid().v4()}';

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

    _mockStore[roomCode] = battle;

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
      throw Exception('Invalid room code. Room codes must be exactly 6 characters.');
    }

    final existing = _mockStore[code];
    if (existing == null) {
      throw Exception('Room "$code" does not exist. Please verify the room code.');
    }

    if (existing.participants.length >= 2) {
      throw Exception('Room "$code" is already full (1v1 maximum reached).');
    }

    if (existing.status != BattleStatus.waitingForPlayer &&
        existing.status != BattleStatus.created) {
      throw Exception('This battle room is no longer accepting new participants.');
    }

    final participantId = const Uuid().v4();
    final participantToken = 'mock_token_${const Uuid().v4()}';

    final guestParticipant = BattleParticipant(
      id: participantId,
      displayName: displayName,
      avatar: avatar ?? 'assets/default_pfp/avatar-spark.svg',
      status: ParticipantStatus.joined,
      isHost: false,
    );

    final updatedParticipants = [...existing.participants, guestParticipant];

    final updatedBattle = existing.copyWith(
      status: BattleStatus.waitingForReady,
      participants: updatedParticipants,
    );

    _mockStore[code] = updatedBattle;

    return BattleJoinResponse(
      battleId: existing.id,
      participantId: participantId,
      participantToken: participantToken,
      battle: updatedBattle,
    );
  }

  @override
  Future<BattleSessionModel> getBattleStatus({
    required String battleId,
    required String participantToken,
  }) async {
    return _mockStore.values.firstWhere(
      (b) => b.id == battleId,
      orElse: () => BattleSessionModel(
        id: battleId,
        roomCode: 'MOCK01',
        durationMinutes: 25,
        status: BattleStatus.active,
        createdAt: DateTime.now(),
      ),
    );
  }
}
