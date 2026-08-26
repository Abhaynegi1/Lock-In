import 'dart:async';
import 'package:flutter/material.dart';
import '../models/battle_event.dart';
import '../models/battle_state.dart';
import '../models/focus_session.dart';
import '../services/battle_realtime_data_source.dart';
import '../services/battle_repository.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

class BattleProvider with ChangeNotifier {
  final BattleRepository _repository;
  final StorageService _storageService;

  StreamSubscription<BattleEvent>? _eventSubscription;
  StreamSubscription<BattleConnectionState>? _connectionSubscription;

  BattleSessionModel? _currentBattle;
  String? _localParticipantId;
  String? _participantToken;
  BattleConnectionState _connectionState = BattleConnectionState.disconnected;
  BattleStatus _status = BattleStatus.created;

  // Authoritative server timestamps
  DateTime? _serverStartTime;
  DateTime? _serverEndTime;
  int _totalDurationSeconds = 0;
  int _secondsRemaining = 0;
  Timer? _uiTickerTimer;

  // Lobby countdown (3, 2, 1...)
  int _lobbyCountdown = 0;
  Timer? _lobbyCountdownTimer;

  // Opponent disconnect grace timer
  int _gracePeriodSecondsRemaining = 0;
  Timer? _graceTimer;

  BattleResultModel? _lastResult;
  List<BattleSessionModel> _localBattleHistory = [];
  String? _errorMessage;
  bool _isLoading = false;

  // Getters
  BattleSessionModel? get currentBattle => _currentBattle;
  String? get localParticipantId => _localParticipantId;
  String? get participantToken => _participantToken;
  BattleConnectionState get connectionState => _connectionState;
  BattleStatus get status => _status;
  int get secondsRemaining => _secondsRemaining;
  int get totalDurationSeconds => _totalDurationSeconds;
  int get lobbyCountdown => _lobbyCountdown;
  int get gracePeriodSecondsRemaining => _gracePeriodSecondsRemaining;
  BattleResultModel? get lastResult => _lastResult;
  List<BattleSessionModel> get localBattleHistory => _localBattleHistory;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  BattleParticipant? get localParticipant =>
      _currentBattle?.findParticipant(_localParticipantId ?? '');

  BattleParticipant? get opponentParticipant =>
      _currentBattle?.getOpponent(_localParticipantId ?? '');

  bool get isHost => localParticipant?.isHost ?? false;
  bool get isLocalReady => localParticipant?.isReady ?? false;
  bool get isOpponentReady => opponentParticipant?.isReady ?? false;

  double get progress => _totalDurationSeconds > 0
      ? (_secondsRemaining / _totalDurationSeconds).clamp(0.0, 1.0)
      : 0.0;

  double get completionRatio => _totalDurationSeconds > 0
      ? ((_totalDurationSeconds - _secondsRemaining) / _totalDurationSeconds)
            .clamp(0.0, 1.0)
      : 0.0;

  String get timerString {
    final int minutes = _secondsRemaining ~/ 60;
    final int seconds = _secondsRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  BattleProvider({BattleRepository? repository, StorageService? storageService})
    : _repository = repository ?? BattleRepository(),
      _storageService = storageService ?? StorageService() {
    _init();
  }

  Future<void> _init() async {
    await loadLocalHistory();
    _subscribeToStreams();
  }

  void _subscribeToStreams() {
    _eventSubscription?.cancel();
    _eventSubscription = _repository.eventStream.listen(_handleIncomingEvent);

    _connectionSubscription?.cancel();
    _connectionSubscription = _repository.connectionStateStream.listen((state) {
      _connectionState = state;
      notifyListeners();
    });
  }

  Future<void> loadLocalHistory() async {
    _localBattleHistory = await _repository.getLocalBattleSessions();
    _safeNotify();
  }

  /// Create a new battle room as guest host
  Future<bool> createBattle({
    required int durationMinutes,
    required String displayName,
    String? avatar,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.createBattle(
        durationMinutes: durationMinutes,
        displayName: displayName,
        avatar: avatar,
      );

      _currentBattle = response.battle;
      _localParticipantId = response.participantId;
      _participantToken = response.participantToken;
      _status = response.battle.status;

      await _repository.connectRealtime(
        battleId: response.battleId,
        participantToken: response.participantToken,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Could not create battle room: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Join an existing room via 6-character room code
  Future<bool> joinBattle({
    required String roomCode,
    required String displayName,
    String? avatar,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.joinBattle(
        roomCode: roomCode,
        displayName: displayName,
        avatar: avatar,
      );

      _currentBattle = response.battle;
      _localParticipantId = response.participantId;
      _participantToken = response.participantToken;
      _status = response.battle.status;

      await _repository.connectRealtime(
        battleId: response.battleId,
        participantToken: response.participantToken,
      );

      // Notify host via real-time that guest has joined
      await _repository.sendEvent(
        BattleEvent(
          type: BattleEventType.playerJoined,
          battleId: response.battleId,
          timestamp: DateTime.now(),
          payload: {'participant': localParticipant?.toMap() ?? {}},
        ),
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Could not join battle room. Please verify the code.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Toggle or set ready state in the lobby
  Future<void> toggleReady() async {
    if (_currentBattle == null || _localParticipantId == null) return;

    final currentlyReady = isLocalReady;
    final newStatus = currentlyReady
        ? ParticipantStatus.joined
        : ParticipantStatus.ready;

    _updateParticipantStatus(_localParticipantId!, newStatus);

    final event = currentlyReady
        ? BattleEvent.playerUnready(
            battleId: _currentBattle!.id,
            participantId: _localParticipantId!,
          )
        : BattleEvent.playerReady(
            battleId: _currentBattle!.id,
            participantId: _localParticipantId!,
          );

    await _repository.sendEvent(event);

    _checkIfBothReadyToStart();
    notifyListeners();
  }

  void _checkIfBothReadyToStart() {
    if (_currentBattle != null && _currentBattle!.areBothReady) {
      _startLobbyCountdown();
    }
  }

  void _startLobbyCountdown() {
    _lobbyCountdownTimer?.cancel();
    _lobbyCountdown = 3;
    _status = BattleStatus.countdown;
    notifyListeners();

    _lobbyCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lobbyCountdown > 1) {
        _lobbyCountdown--;
        notifyListeners();
      } else {
        _lobbyCountdown = 0;
        _lobbyCountdownTimer?.cancel();
        _startAuthoritativeBattle();
      }
    });
  }

  void _startAuthoritativeBattle() {
    if (_currentBattle == null) return;

    final now = DateTime.now();
    final totalSeconds = _currentBattle!.durationMinutes * 60;
    _serverStartTime = now;
    _serverEndTime = now.add(Duration(seconds: totalSeconds));
    _totalDurationSeconds = totalSeconds;
    _secondsRemaining = totalSeconds;
    _status = BattleStatus.active;

    // Update all participants to active
    final updatedParticipants = _currentBattle!.participants.map((p) {
      return p.copyWith(status: ParticipantStatus.active);
    }).toList();

    _currentBattle = _currentBattle!.copyWith(
      status: BattleStatus.active,
      startedAt: _serverStartTime,
      endsAt: _serverEndTime,
      participants: updatedParticipants,
    );

    _startUiTimerTicker();
    _syncNotification();
    notifyListeners();
  }

  void _startUiTimerTicker() {
    _uiTickerTimer?.cancel();
    _uiTickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_serverEndTime != null) {
        final diff = _serverEndTime!.difference(DateTime.now()).inSeconds;
        if (diff > 0) {
          _secondsRemaining = diff;
          notifyListeners();
          _syncNotification();
        } else {
          _secondsRemaining = 0;
          _completeBattleSuccessfully();
        }
      }
    });
  }

  /// Synchronize clock with server timestamps after lifecycle resume
  void syncAuthoritativeTimer() {
    if (_status != BattleStatus.active || _serverEndTime == null) return;
    final diff = _serverEndTime!.difference(DateTime.now()).inSeconds;
    if (diff > 0) {
      _secondsRemaining = diff;
      notifyListeners();
      _syncNotification();
    } else {
      _secondsRemaining = 0;
      _completeBattleSuccessfully();
    }
  }

  /// Lock-In violation or intentional forfeit
  Future<void> forfeitBattle({String reason = 'Left the application'}) async {
    if (_currentBattle == null || _localParticipantId == null) return;

    _uiTickerTimer?.cancel();
    _graceTimer?.cancel();
    _cancelNotification();

    // Mark local participant as forfeited
    _updateParticipantStatus(_localParticipantId!, ParticipantStatus.forfeited);

    await _repository.sendEvent(
      BattleEvent.playerForfeited(
        battleId: _currentBattle!.id,
        participantId: _localParticipantId!,
        reason: reason,
      ),
    );

    final opponent = opponentParticipant;
    final winnerId = opponent?.id;

    _finalizeBattleResult(
      winnerId: winnerId,
      isForfeit: true,
      forfeitParticipantId: _localParticipantId,
    );
  }

  /// Successful completion when timer reaches 0:00
  Future<void> _completeBattleSuccessfully() async {
    if (_currentBattle == null || _localParticipantId == null) return;

    _uiTickerTimer?.cancel();
    _graceTimer?.cancel();

    _updateParticipantStatus(
      _localParticipantId!,
      ParticipantStatus.finished,
      focusedSeconds: _totalDurationSeconds,
    );

    await _repository.sendEvent(
      BattleEvent.playerFinished(
        battleId: _currentBattle!.id,
        participantId: _localParticipantId!,
        focusedSeconds: _totalDurationSeconds,
      ),
    );

    // If opponent is also finished or both reached end, determine winner
    _finalizeBattleResult(
      winnerId: _localParticipantId, // Both focused target duration
      isDraw: opponentParticipant?.isFinished ?? true,
      isForfeit: false,
    );
  }

  void _finalizeBattleResult({
    String? winnerId,
    bool isDraw = false,
    bool isForfeit = false,
    String? forfeitParticipantId,
  }) async {
    _status = BattleStatus.completed;
    _uiTickerTimer?.cancel();
    _graceTimer?.cancel();
    _cancelNotification();

    final localP =
        localParticipant ??
        const BattleParticipant(
          id: 'local',
          displayName: 'You',
          status: ParticipantStatus.finished,
        );

    final opponentP =
        opponentParticipant ??
        const BattleParticipant(
          id: 'opponent',
          displayName: 'Opponent',
          status: ParticipantStatus.finished,
        );

    _lastResult = BattleResultModel(
      battleId:
          _currentBattle?.id ??
          'battle_${DateTime.now().millisecondsSinceEpoch}',
      roomCode: _currentBattle?.roomCode ?? '------',
      winnerParticipantId: isDraw ? null : winnerId,
      isDraw: isDraw,
      localParticipant: localP,
      opponentParticipant: opponentP,
      completedAt: DateTime.now(),
      isForfeit: isForfeit,
      forfeitParticipantId: forfeitParticipantId,
    );

    if (_currentBattle != null) {
      final completedBattle = _currentBattle!.copyWith(
        status: BattleStatus.completed,
        winnerId: winnerId,
        forfeitReason: isForfeit ? 'Participant forfeited' : null,
      );
      await _repository.persistBattleSession(completedBattle);
      await _saveToSoloFocusHistory(completedBattle, localP.isFinished);
      await loadLocalHistory();
    }

    _safeNotify();
  }

  Future<void> _saveToSoloFocusHistory(
    BattleSessionModel battle,
    bool isWin,
  ) async {
    final session = FocusSession(
      id: battle.id,
      durationMinutes: battle.durationMinutes,
      targetDurationMinutes: battle.durationMinutes,
      dateTime: DateTime.now(),
      isWin: isWin,
      sessionType: SessionType.battle,
      opponentName: opponentParticipant?.displayName ?? 'Opponent',
      opponentScore: isWin ? 'Victory' : 'Forfeited',
    );
    await _storageService.saveSession(session);
  }

  void _handleIncomingEvent(BattleEvent event) {
    if (_currentBattle == null || event.battleId != _currentBattle!.id) {
      return;
    }

    switch (event.type) {
      case BattleEventType.playerJoined:
        final participantMap = event.payload['participant'];
        if (participantMap != null) {
          final joinedParticipant = BattleParticipant.fromMap(
            Map<String, dynamic>.from(participantMap),
          );
          if (_currentBattle!.findParticipant(joinedParticipant.id) == null) {
            _currentBattle = _currentBattle!.copyWith(
              status: BattleStatus.waitingForReady,
              participants: [
                ..._currentBattle!.participants,
                joinedParticipant,
              ],
            );
            notifyListeners();
          }
        }
        break;

      case BattleEventType.playerReady:
        final pId = event.payload['participantId']?.toString();
        if (pId != null) {
          _updateParticipantStatus(pId, ParticipantStatus.ready);
          _checkIfBothReadyToStart();
          notifyListeners();
        }
        break;

      case BattleEventType.playerUnready:
        final pId = event.payload['participantId']?.toString();
        if (pId != null) {
          _lobbyCountdownTimer?.cancel();
          _lobbyCountdown = 0;
          _status = BattleStatus.waitingForReady;
          _updateParticipantStatus(pId, ParticipantStatus.joined);
          notifyListeners();
        }
        break;

      case BattleEventType.battleStarted:
        final startedAtStr = event.payload['startedAt']?.toString();
        final duration =
            event.payload['durationSeconds'] as int? ??
            (_currentBattle!.durationMinutes * 60);

        _serverStartTime = startedAtStr != null
            ? DateTime.tryParse(startedAtStr) ?? DateTime.now()
            : DateTime.now();
        _serverEndTime = _serverStartTime!.add(Duration(seconds: duration));
        _totalDurationSeconds = duration;
        _secondsRemaining = duration;
        _status = BattleStatus.active;
        _startUiTimerTicker();
        _syncNotification();
        notifyListeners();
        break;

      case BattleEventType.playerForfeited:
        final pId = event.payload['participantId']?.toString();
        if (pId != null) {
          _updateParticipantStatus(pId, ParticipantStatus.forfeited);
          // If opponent forfeited, local player wins!
          if (pId != _localParticipantId) {
            _finalizeBattleResult(
              winnerId: _localParticipantId,
              isForfeit: true,
              forfeitParticipantId: pId,
            );
          }
        }
        break;

      case BattleEventType.playerDisconnected:
        final pId = event.payload['participantId']?.toString();
        if (pId != null && pId != _localParticipantId) {
          _updateParticipantStatus(pId, ParticipantStatus.disconnected);
          _status = BattleStatus.playerDisconnected;
          _startOpponentGraceCountdown();
          notifyListeners();
        }
        break;

      case BattleEventType.playerReconnected:
        final pId = event.payload['participantId']?.toString();
        if (pId != null && pId != _localParticipantId) {
          _graceTimer?.cancel();
          _gracePeriodSecondsRemaining = 0;
          _updateParticipantStatus(pId, ParticipantStatus.active);
          _status = BattleStatus.active;
          notifyListeners();
        }
        break;

      case BattleEventType.battleFinished:
        final winnerId = event.payload['winnerId']?.toString();
        final isDraw = event.payload['isDraw'] as bool? ?? false;
        _finalizeBattleResult(winnerId: winnerId, isDraw: isDraw);
        break;

      default:
        break;
    }
  }

  void _startOpponentGraceCountdown() {
    _graceTimer?.cancel();
    _gracePeriodSecondsRemaining = _currentBattle?.gracePeriodSeconds ?? 30;
    notifyListeners();

    _graceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_gracePeriodSecondsRemaining > 1) {
        _gracePeriodSecondsRemaining--;
        notifyListeners();
      } else {
        _gracePeriodSecondsRemaining = 0;
        _graceTimer?.cancel();
        // Opponent failed to reconnect within grace period -> count as forfeit
        final opp = opponentParticipant;
        if (opp != null) {
          _updateParticipantStatus(opp.id, ParticipantStatus.forfeited);
          _finalizeBattleResult(
            winnerId: _localParticipantId,
            isForfeit: true,
            forfeitParticipantId: opp.id,
          );
        }
      }
    });
  }

  void _updateParticipantStatus(
    String participantId,
    ParticipantStatus newStatus, {
    int? focusedSeconds,
  }) {
    if (_currentBattle == null) return;
    final updated = _currentBattle!.participants.map((p) {
      if (p.id == participantId) {
        return p.copyWith(
          status: newStatus,
          focusedSeconds: focusedSeconds ?? p.focusedSeconds,
        );
      }
      return p;
    }).toList();

    _currentBattle = _currentBattle!.copyWith(participants: updated);
  }

  bool _isDisposed = false;

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _syncNotification() {
    if (_status == BattleStatus.active) {
      try {
        NotificationService()
            .updateTimerNotification(
              timeRemaining: timerString,
              title:
                  '⚔️ Battle with ${opponentParticipant?.displayName ?? "Opponent"}',
              isBattle: true,
            )
            .catchError((_) {});
      } catch (_) {}
    }
  }

  void _cancelNotification() {
    try {
      NotificationService().cancelTimerNotification().catchError((_) {});
    } catch (_) {}
  }

  /// Clean up current active battle session and reset to idle
  void resetBattle() {
    _uiTickerTimer?.cancel();
    _lobbyCountdownTimer?.cancel();
    _graceTimer?.cancel();
    _cancelNotification();

    _repository.disconnectRealtime();
    _currentBattle = null;
    _localParticipantId = null;
    _participantToken = null;
    _status = BattleStatus.created;
    _secondsRemaining = 0;
    _totalDurationSeconds = 0;
    _lobbyCountdown = 0;
    _gracePeriodSecondsRemaining = 0;
    _errorMessage = null;
    _safeNotify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _eventSubscription?.cancel();
    _connectionSubscription?.cancel();
    _uiTickerTimer?.cancel();
    _lobbyCountdownTimer?.cancel();
    _graceTimer?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
