import 'dart:convert';

enum SessionType { solo, battle }

class FocusSession {
  final String id;
  final int durationMinutes;
  final DateTime dateTime;
  final bool isWin;
  final SessionType sessionType;
  final String? opponentName;
  final String? opponentScore;

  FocusSession({
    required this.id,
    required this.durationMinutes,
    required this.dateTime,
    required this.isWin,
    this.sessionType = SessionType.solo,
    this.opponentName,
    this.opponentScore,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'durationMinutes': durationMinutes,
      'dateTime': dateTime.toIso8601String(),
      'isWin': isWin,
      'sessionType': sessionType.name,
      'opponentName': opponentName,
      'opponentScore': opponentScore,
    };
  }

  factory FocusSession.fromMap(Map<String, dynamic> map) {
    return FocusSession(
      id: map['id'],
      durationMinutes: map['durationMinutes'],
      dateTime: DateTime.parse(map['dateTime']),
      isWin: map['isWin'],
      sessionType: map['sessionType'] == 'battle'
          ? SessionType.battle
          : SessionType.solo,
      opponentName: map['opponentName'],
      opponentScore: map['opponentScore'],
    );
  }

  String toJson() => json.encode(toMap());

  factory FocusSession.fromJson(String source) =>
      FocusSession.fromMap(json.decode(source));
}
