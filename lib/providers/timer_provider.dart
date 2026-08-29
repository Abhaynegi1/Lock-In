import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/battle_model.dart';
import '../models/focus_session.dart';
import '../services/notification_service.dart';
import '../services/screen_wake_service.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';

enum SessionStatus { idle, running, won, lost }

class TimerProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  Timer? _timer;
  int _secondsRemaining = 0;
  int _totalSeconds = 0;
  int _currentStreak = 0;
  int _selectedDurationMinutes = 45;
  int _dailyGoalMinutes = 240; // 4 hours
  String _userName = 'Lock In Member';
  String _userAvatar = StorageService.defaultAvatar;
  bool _isStrictAntiDistraction = true;
  DateTime? _sessionEndTime;
  SessionStatus _status = SessionStatus.idle;
  SessionType _activeSessionType = SessionType.solo;
  BattleModel? _activeBattle;
  List<FocusSession> _history = [];
  List<BattleModel> _battles = [];

  int get secondsRemaining => _secondsRemaining;
  int get totalSeconds => _totalSeconds;
  int get currentStreak => _currentStreak;
  int get selectedDurationMinutes => _selectedDurationMinutes;
  int get dailyGoalMinutes => _dailyGoalMinutes;
  String get userName => _userName;
  String get userAvatar => _userAvatar;
  bool get isStrictAntiDistraction => _isStrictAntiDistraction;
  SessionStatus get status => _status;
  SessionType get activeSessionType => _activeSessionType;
  BattleModel? get activeBattle => _activeBattle;
  List<FocusSession> get history => _history;
  List<BattleModel> get battles => _battles;

  BattleModel? get featuredBattle =>
      _battles.isNotEmpty ? _battles.first : null;

  double get progress =>
      _totalSeconds > 0 ? _secondsRemaining / _totalSeconds : 0.0;

  double get completionRatio => _totalSeconds > 0
      ? (_totalSeconds - _secondsRemaining) / _totalSeconds
      : 0.0;

  String get timerString {
    final int minutes = _secondsRemaining ~/ 60;
    final int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get selectedTimerFormatted {
    return '${_selectedDurationMinutes.toString().padLeft(2, '0')}:00';
  }

  // Real today's focus calculation based on completed focused minutes recorded
  int get todayFocusMinutes {
    final now = DateTime.now();
    int minutes = 0;
    for (var s in _history) {
      if (s.isWin &&
          s.dateTime.year == now.year &&
          s.dateTime.month == now.month &&
          s.dateTime.day == now.day) {
        minutes += s.durationMinutes;
      }
    }
    return minutes;
  }

  String get todayProgressText {
    final mins = todayFocusMinutes;
    final h = mins ~/ 60;
    final m = mins % 60;
    final goalH = _dailyGoalMinutes ~/ 60;
    final formattedTime = h > 0 ? '${h}h ${m}m' : '${m}m';
    return '$formattedTime / ${goalH}h';
  }

  double get todayProgressRatio {
    if (_dailyGoalMinutes <= 0) return 0.0;
    return (todayFocusMinutes / _dailyGoalMinutes).clamp(0.0, 1.0);
  }

  TimerProvider() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _currentStreak = await _storageService.getStreak();
    _history = await _storageService.getHistory();
    _battles = await _storageService.getBattles();
    _dailyGoalMinutes = await _storageService.getDailyGoalMinutes();
    _userName = await _storageService.getUserName();
    _userAvatar = await _storageService.getUserAvatar();
    _isStrictAntiDistraction = await _storageService.getStrictAntiDistraction();
    notifyListeners();
  }

  Future<void> refreshFromStorage() async {
    await _loadInitialData();
  }

  Future<void> updateUserName(String name) async {
    _userName = name.trim().isEmpty ? 'Lock In Member' : name.trim();
    await _storageService.saveUserName(_userName);
    notifyListeners();
    _autoSyncCloud();
  }

  Future<void> updateUserAvatar(String avatarPath) async {
    _userAvatar = avatarPath.trim().isEmpty
        ? StorageService.defaultAvatar
        : avatarPath.trim();
    await _storageService.saveUserAvatar(_userAvatar);
    notifyListeners();
    _autoSyncCloud();
  }

  Future<void> updateDailyGoalMinutes(int minutes) async {
    _dailyGoalMinutes = minutes.clamp(15, 960);
    await _storageService.saveDailyGoalMinutes(_dailyGoalMinutes);
    notifyListeners();
    _autoSyncCloud();
  }

  Future<void> updateDailyGoalHours(int hours) async {
    await updateDailyGoalMinutes(hours * 60);
  }

  Future<void> setStrictAntiDistraction(bool value) async {
    _isStrictAntiDistraction = value;
    await _storageService.saveStrictAntiDistraction(value);
    if (_status == SessionStatus.running) {
      await ScreenWakeService.setEnabled(value);
    }
    notifyListeners();
    _autoSyncCloud();
  }

  Future<void> toggleStrictAntiDistraction() async {
    await setStrictAntiDistraction(!_isStrictAntiDistraction);
  }

  void selectDuration(int minutes) {
    _selectedDurationMinutes = minutes;
    notifyListeners();
  }

  void _syncNotification() {
    if (_status == SessionStatus.running) {
      final title = _activeSessionType == SessionType.battle
          ? 'Battle with ${_activeBattle?.opponentName ?? "Opponent"}'
          : 'Solo Focus';
      NotificationService().updateTimerNotification(
        timeRemaining: timerString,
        title: title,
        isBattle: _activeSessionType == SessionType.battle,
      );
    }
  }

  void startSession({
    int? minutes,
    SessionType type = SessionType.solo,
    BattleModel? battle,
  }) {
    _activeSessionType = type;
    _activeBattle =
        battle ?? (type == SessionType.battle ? featuredBattle : null);
    final duration = minutes ?? _selectedDurationMinutes;
    _status = SessionStatus.running;
    _totalSeconds = duration * 60;
    _secondsRemaining = _totalSeconds;
    _sessionEndTime = DateTime.now().add(Duration(seconds: _totalSeconds));
    if (_isStrictAntiDistraction) {
      unawaited(ScreenWakeService.enable());
    }
    notifyListeners();
    _syncNotification();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_sessionEndTime != null) {
        final diff = _sessionEndTime!.difference(DateTime.now()).inSeconds;
        if (diff > 0) {
          _secondsRemaining = diff;
          notifyListeners();
          _syncNotification();
        } else {
          _secondsRemaining = 0;
          _onSessionComplete(true);
        }
      } else {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          notifyListeners();
          _syncNotification();
        } else {
          _onSessionComplete(true);
        }
      }
    });
  }

  void syncTimer() {
    if (_status != SessionStatus.running || _sessionEndTime == null) return;
    final diff = _sessionEndTime!.difference(DateTime.now()).inSeconds;
    if (diff > 0) {
      _secondsRemaining = diff;
      notifyListeners();
      _syncNotification();
    } else {
      _secondsRemaining = 0;
      _onSessionComplete(true);
    }
  }

  void forfeitSession() {
    if (_status == SessionStatus.running) {
      NotificationService().cancelTimerNotification();
      _onSessionComplete(false);
    }
  }

  Future<void> _onSessionComplete(bool isWin) async {
    _timer?.cancel();
    await ScreenWakeService.disable();
    _status = isWin ? SessionStatus.won : SessionStatus.lost;

    final targetDuration = _totalSeconds ~/ 60;
    final elapsedSeconds = _totalSeconds - _secondsRemaining;

    // Calculate actual elapsed minutes spent focusing
    int actualFocusedMinutes;
    if (isWin) {
      actualFocusedMinutes = targetDuration;
    } else {
      actualFocusedMinutes = (elapsedSeconds / 60).round();
    }

    if (isWin) {
      await NotificationService().showSessionCompleteNotification(
        title: '🎉 Focus Block Completed!',
        body:
            'You completed $actualFocusedMinutes minutes of deep focus unbroken.',
      );
    } else {
      await NotificationService().cancelTimerNotification();
    }

    final session = FocusSession(
      id: const Uuid().v4(),
      durationMinutes: actualFocusedMinutes,
      targetDurationMinutes: targetDuration,
      dateTime: DateTime.now(),
      isWin: isWin,
      sessionType: _activeSessionType,
      opponentName: _activeBattle?.opponentName,
      opponentScore: _activeBattle?.scoreComparison,
    );

    if (_activeBattle != null && actualFocusedMinutes > 0) {
      // Add minutes to active battle
      final updatedBattles = _battles.map((b) {
        if (b.id == _activeBattle!.id) {
          return b.copyWith(userMinutes: b.userMinutes + actualFocusedMinutes);
        }
        return b;
      }).toList();
      _battles = updatedBattles;
      await _storageService.saveBattles(_battles);
    }

    await _storageService.saveSession(session);
    _currentStreak = await _storageService.getStreak();
    _history = await _storageService.getHistory();
    notifyListeners();
    _autoSyncCloud();
  }

  Future<void> createBattle(
    String opponentName,
    int targetDurationHours,
  ) async {
    final initials = opponentName.trim().isNotEmpty
        ? opponentName.trim()[0].toUpperCase()
        : 'F';
    final newBattle = BattleModel(
      id: const Uuid().v4(),
      opponentName: opponentName.trim(),
      opponentInitials: initials,
      userMinutes: 0,
      opponentMinutes: 0,
      endsIn: '${targetDurationHours}h',
      isActive: true,
    );
    _battles.insert(0, newBattle);
    await _storageService.saveBattles(_battles);
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    unawaited(ScreenWakeService.disable());
    NotificationService().cancelTimerNotification();
    _status = SessionStatus.idle;
    _secondsRemaining = 0;
    _totalSeconds = 0;
    _activeBattle = null;
    notifyListeners();
  }

  void _autoSyncCloud() {
    final supabase = SupabaseService();
    if (supabase.isAuthenticated) {
      supabase.syncLocalDataToCloud(
        localSessions: _history,
        userName: _userName,
        userAvatar: _userAvatar,
        streak: _currentStreak,
        dailyGoalMinutes: _dailyGoalMinutes,
        isStrictAntiDistraction: _isStrictAntiDistraction,
      );
    }
  }
}
