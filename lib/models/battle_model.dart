import 'dart:convert';

class BattleModel {
  final String id;
  final String opponentName;
  final String opponentInitials;
  final int userMinutes;
  final int opponentMinutes;
  final String endsIn;
  final bool isActive;

  const BattleModel({
    required this.id,
    required this.opponentName,
    required this.opponentInitials,
    required this.userMinutes,
    required this.opponentMinutes,
    required this.endsIn,
    this.isActive = true,
  });

  bool get isUserAhead => userMinutes >= opponentMinutes;

  String get scoreComparison => '$userMinutes—$opponentMinutes';

  BattleModel copyWith({
    String? id,
    String? opponentName,
    String? opponentInitials,
    int? userMinutes,
    int? opponentMinutes,
    String? endsIn,
    bool? isActive,
  }) {
    return BattleModel(
      id: id ?? this.id,
      opponentName: opponentName ?? this.opponentName,
      opponentInitials: opponentInitials ?? this.opponentInitials,
      userMinutes: userMinutes ?? this.userMinutes,
      opponentMinutes: opponentMinutes ?? this.opponentMinutes,
      endsIn: endsIn ?? this.endsIn,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'opponentName': opponentName,
      'opponentInitials': opponentInitials,
      'userMinutes': userMinutes,
      'opponentMinutes': opponentMinutes,
      'endsIn': endsIn,
      'isActive': isActive,
    };
  }

  factory BattleModel.fromMap(Map<String, dynamic> map) {
    return BattleModel(
      id: map['id'] ?? '',
      opponentName: map['opponentName'] ?? '',
      opponentInitials: map['opponentInitials'] ?? '',
      userMinutes: map['userMinutes']?.toInt() ?? 0,
      opponentMinutes: map['opponentMinutes']?.toInt() ?? 0,
      endsIn: map['endsIn'] ?? 'ends in 2h',
      isActive: map['isActive'] ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory BattleModel.fromJson(String source) =>
      BattleModel.fromMap(json.decode(source));
}
