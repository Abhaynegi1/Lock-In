import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import 'timer_provider.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final StorageService _storageService = StorageService();

  StreamSubscription<AuthState>? _authSubscription;
  User? _currentUser;
  bool _isSyncing = false;
  DateTime? _lastSyncedAt;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get errorMessage => _errorMessage;

  String get userEmail => _currentUser?.email ?? 'No email';
  String get userDisplayName =>
      _currentUser?.userMetadata?['full_name'] ??
      _currentUser?.userMetadata?['name'] ??
      _currentUser?.email?.split('@').first ??
      'Lock In Member';

  String? get userAvatarUrl =>
      _currentUser?.userMetadata?['avatar_url'] ??
      _currentUser?.userMetadata?['picture'];

  AuthProvider() {
    _init();
  }

  void _init() {
    _currentUser = _supabaseService.currentUser;
    if (_currentUser != null) {
      // Auto-sync in background on app start
      syncData();
    }
    _authSubscription = _supabaseService.authStateChanges.listen((data) {
      final wasNull = _currentUser == null;
      _currentUser = data.session?.user;
      notifyListeners();

      if (data.event == AuthChangeEvent.signedIn ||
          (wasNull && _currentUser != null)) {
        syncData();
      }
    });
  }

  Future<bool> signInWithGoogle({TimerProvider? timerProvider}) async {
    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _supabaseService.signInWithGoogle();
      _currentUser = _supabaseService.currentUser;

      if (_currentUser != null) {
        // Run initial bi-directional sync
        await syncData(timerProvider: timerProvider);
      }

      _isSyncing = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst(
        RegExp(r'^(Exception|AuthException):\s*'),
        '',
      );
      _isSyncing = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    _isSyncing = true;
    notifyListeners();

    try {
      await _supabaseService.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> syncData({TimerProvider? timerProvider}) async {
    if (!isAuthenticated) return;

    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Fetch remote changes and merge
      await _supabaseService.fetchAndMergeCloudData(_storageService);

      // 2. Upload local updates to Supabase
      final localSessions = await _storageService.getHistory();
      final streak = await _storageService.getStreak();
      final userName = await _storageService.getUserName();
      final userAvatar = await _storageService.getUserAvatar();
      final dailyGoalMinutes = await _storageService.getDailyGoalMinutes();
      final isStrict = await _storageService.getStrictAntiDistraction();

      await _supabaseService.syncLocalDataToCloud(
        localSessions: localSessions,
        userName: userName,
        userAvatar: userAvatar,
        streak: streak,
        dailyGoalMinutes: dailyGoalMinutes,
        isStrictAntiDistraction: isStrict,
      );

      _lastSyncedAt = DateTime.now();

      // Refresh timer provider if passed
      if (timerProvider != null) {
        await timerProvider.refreshFromStorage();
      }
    } catch (e) {
      debugPrint('Sync failed: $e');
      _errorMessage = 'Sync encountered an issue: $e';
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
