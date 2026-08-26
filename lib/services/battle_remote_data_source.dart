import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
    final rand = DateTime.now().millisecondsSinceEpoch;
    var code = '';
    var n = rand;
    for (int i = 0; i < 6; i++) {
      code += chars[n % chars.length];
      n ~/= 10;
    }
    return code;
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
    final existing = _mockStore[code];

    final battleId = existing?.id ?? const Uuid().v4();
    final participantId = const Uuid().v4();
    final participantToken = 'mock_token_${const Uuid().v4()}';

    final guestParticipant = BattleParticipant(
      id: participantId,
      displayName: displayName,
      avatar: avatar ?? 'assets/default_pfp/avatar-spark.svg',
      status: ParticipantStatus.joined,
      isHost: false,
    );

    List<BattleParticipant> participants = [];
    if (existing != null) {
      participants = [...existing.participants, guestParticipant];
    } else {
      // Create mock host if room didn't exist
      participants = [
        const BattleParticipant(
          id: 'mock_host_id',
          displayName: 'Player 1',
          status: ParticipantStatus.ready,
          isHost: true,
        ),
        guestParticipant,
      ];
    }

    final updatedBattle =
        (existing ??
                BattleSessionModel(
                  id: battleId,
                  roomCode: code,
                  durationMinutes: 25,
                  createdAt: DateTime.now(),
                ))
            .copyWith(
              status: BattleStatus.waitingForReady,
              participants: participants,
            );

    _mockStore[code] = updatedBattle;

    return BattleJoinResponse(
      battleId: battleId,
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
