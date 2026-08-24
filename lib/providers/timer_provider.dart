import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/battle_model.dart';
import '../models/focus_session.dart';
import '../services/storage_service.dart';

enum SessionStatus { idle, running, won, lost }

class TimerProvider with ChangeNotifier {
  final StorageService _storageService = StorageService();
  Timer? _timer;
  int _secondsRemaining = 0;
  int _totalSeconds = 0;
  int _currentStreak = 0;
  int _selectedDurationMinutes = 45;
  int _dailyGoalMinutes = 240; // 4 hours
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
  SessionStatus get status => _status;
  SessionType get activeSessionType => _activeSessionType;
  BattleModel? get activeBattle => _activeBattle;
  List<FocusSession> get history => _history;
  List<BattleModel> get battles => _battles;

  BattleModel? get featuredBattle =>
      _battles.isNotEmpty ? _battles.first : null;

  double get progress =>
      _totalSeconds > 0 ? _secondsRemaining / _totalSeconds : 0.0;

  double get completionRatio =>
      _totalSeconds > 0 ? (_totalSeconds - _secondsRemaining) / _totalSeconds : 0.0;

  String get timerString {
    int minutes = _secondsRemaining ~/ 60;
    int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get selectedTimerFormatted {
    return '${_selectedDurationMinutes.toString().padLeft(2, '0')}:00';
  }

  // Real today's focus calculation based only on completed sessions
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
    notifyListeners();
  }

  void selectDuration(int minutes) {
    _selectedDurationMinutes = minutes;
    notifyListeners();
  }

  void startSession({int? minutes, SessionType type = SessionType.solo, BattleModel? battle}) {
    _activeSessionType = type;
    _activeBattle = battle ?? (type == SessionType.battle ? featuredBattle : null);
    final duration = minutes ?? _selectedDurationMinutes;
    _status = SessionStatus.running;
    _totalSeconds = duration * 60;
    _secondsRemaining = _totalSeconds;
    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        _secondsRemaining--;
        notifyListeners();
      } else {
        _onSessionComplete(true);
      }
    });
  }

  void forfeitSession() {
    if (_status == SessionStatus.running) {
      _onSessionComplete(false);
    }
  }

  Future<void> _onSessionComplete(bool isWin) async {
    _timer?.cancel();
    _status = isWin ? SessionStatus.won : SessionStatus.lost;
    final completedDuration = _totalSeconds ~/ 60;

    final session = FocusSession(
      id: const Uuid().v4(),
      durationMinutes: completedDuration,
      dateTime: DateTime.now(),
      isWin: isWin,
      sessionType: _activeSessionType,
      opponentName: _activeBattle?.opponentName,
      opponentScore: _activeBattle?.scoreComparison,
    );

    if (isWin && _activeBattle != null) {
      // Add minutes to active battle
      final updatedBattles = _battles.map((b) {
        if (b.id == _activeBattle!.id) {
          return b.copyWith(userMinutes: b.userMinutes + completedDuration);
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
  }

  Future<void> createBattle(String opponentName, int targetDurationHours) async {
    final initials = opponentName.trim().isNotEmpty
        ? opponentName.trim()[0].toUpperCase()
        : 'F';
    final newBattle = BattleModel(
      id: const Uuid().v4(),
      opponentName: opponentName,
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
    _status = SessionStatus.idle;
    _secondsRemaining = 0;
    _totalSeconds = 0;
    _activeBattle = null;
    notifyListeners();
  }
}
