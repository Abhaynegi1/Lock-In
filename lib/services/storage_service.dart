import 'package:shared_preferences/shared_preferences.dart';
import '../models/battle_model.dart';
import '../models/focus_session.dart';

class StorageService {
  static const String _historyKey = 'focus_history';
  static const String _streakKey = 'focus_streak';
  static const String _battlesKey = 'focus_battles';
  static const String _dailyGoalKey = 'focus_daily_goal';
  static const String _userNameKey = 'focus_username';
  static const String _userAvatarKey = 'focus_user_avatar';
  static const String defaultAvatar = 'assets/default_pfp/avatar-spark.svg';
  static const String _strictAntiDistractionKey =
      'focus_strict_anti_distraction';

  Future<String> getUserAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userAvatarKey) ?? defaultAvatar;
  }

  Future<void> saveUserAvatar(String avatarPath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userAvatarKey, avatarPath);
  }

  Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey) ?? 'Lock In Member';
  }

  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  Future<bool> getStrictAntiDistraction() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_strictAntiDistractionKey) ?? true;
  }

  Future<void> saveStrictAntiDistraction(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_strictAntiDistractionKey, value);
  }

  Future<void> saveSession(FocusSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList(_historyKey) ?? [];
    history.add(session.toJson());
    await prefs.setStringList(_historyKey, history);

    if (session.isWin) {
      final int streak = await getStreak();
      await prefs.setInt(_streakKey, streak + 1);
    } else {
      await prefs.setInt(_streakKey, 0);
    }
  }

  Future<List<FocusSession>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> history = prefs.getStringList(_historyKey) ?? [];
    return history
        .map((s) {
          try {
            return FocusSession.fromJson(s);
          } catch (_) {
            return null;
          }
        })
        .whereType<FocusSession>()
        .toList()
        .reversed
        .toList();
  }

  Future<int> getStreak() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_streakKey) ?? 0;
  }

  Future<List<BattleModel>> getBattles() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? stored = prefs.getStringList(_battlesKey);
    if (stored == null) {
      return [];
    }
    // Filter out any previously seeded hardcoded mock battles (e.g. b1, b2)
    final battles = stored
        .map((s) => BattleModel.fromJson(s))
        .where((b) => b.id != 'b1' && b.id != 'b2')
        .toList();
    return battles;
  }

  Future<void> saveBattles(List<BattleModel> battles) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encoded = battles.map((b) => b.toJson()).toList();
    await prefs.setStringList(_battlesKey, encoded);
  }

  Future<int> getDailyGoalMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyGoalKey) ?? 240; // 4 hours default
  }

  Future<void> saveDailyGoalMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyGoalKey, minutes);
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
    await prefs.remove(_streakKey);
    await prefs.remove(_battlesKey);
  }
}
