import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/focus_session.dart';
import 'storage_service.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String supabaseUrl = 'https://xnnoastptbfeleguojzr.supabase.co';
  static const String supabaseAnonKey =
      'sb_publishable_eLVXDDrtl2z9kH5duJFIpQ_-pQvaoES';

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  SupabaseClient get client => Supabase.instance.client;

  User? get currentUser => _isInitialized ? client.auth.currentUser : null;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges =>
      Supabase.instance.client.auth.onAuthStateChange;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        publishableKey: supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
      );
      _isInitialized = true;
    } catch (e) {
      debugPrint('Supabase init warning: $e');
    }
  }

  /// Authenticate using Google OAuth or Native Google Sign-In
  Future<bool> signInWithGoogle() async {
    if (!_isInitialized) await init();

    try {
      // 1. Try Native Google Sign In if on mobile
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final googleUser = await googleSignIn.signIn();
        if (googleUser != null) {
          final googleAuth = await googleUser.authentication;
          final idToken = googleAuth.idToken;
          final accessToken = googleAuth.accessToken;

          if (idToken != null) {
            final authResponse = await client.auth.signInWithIdToken(
              provider: OAuthProvider.google,
              idToken: idToken,
              accessToken: accessToken,
            );
            if (authResponse.user != null) {
              return true;
            }
          }
        }
      } catch (nativeErr) {
        debugPrint('Native Google Sign-In not available/failed: $nativeErr');
      }

      // 2. Fallback to Supabase OAuth (Web / Deep link callback)
      final res = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb
            ? null
            : 'io.supabase.lockin://login-callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      return res;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      rethrow;
    }
  }

  /// Sign out from Supabase and Google
  Future<void> signOut() async {
    if (!_isInitialized) return;
    try {
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
      } catch (_) {}
      await client.auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }

  /// Upload local focus sessions and profile to Supabase in the background
  Future<void> syncLocalDataToCloud({
    required List<FocusSession> localSessions,
    required String userName,
    required String userAvatar,
    required int streak,
    required int dailyGoalMinutes,
    required bool isStrictAntiDistraction,
  }) async {
    final user = currentUser;
    if (user == null) return;

    try {
      // 1. Upsert profile
      await client.from('profiles').upsert({
        'id': user.id,
        'display_name': userName,
        'avatar_path': userAvatar,
        'streak': streak,
        'daily_goal_minutes': dailyGoalMinutes,
        'is_strict_anti_distraction': isStrictAntiDistraction,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      // 2. Batch upsert completed/recorded sessions
      if (localSessions.isNotEmpty) {
        final sessionRows = localSessions.map((s) {
          return {
            'id': s.id,
            'user_id': user.id,
            'duration_minutes': s.durationMinutes,
            'target_duration_minutes': s.targetDurationMinutes,
            'date_time': s.dateTime.toUtc().toIso8601String(),
            'is_win': s.isWin,
            'session_type': s.sessionType.name,
            'opponent_name': s.opponentName,
            'opponent_score': s.opponentScore,
          };
        }).toList();

        // Upsert in batches of 50 to prevent large payload limits
        for (var i = 0; i < sessionRows.length; i += 50) {
          final chunk = sessionRows.sublist(
            i,
            i + 50 > sessionRows.length ? sessionRows.length : i + 50,
          );
          await client.from('focus_sessions').upsert(chunk);
        }
      }
    } catch (e) {
      debugPrint('Error syncing local data to cloud: $e');
    }
  }

  /// Fetch cloud focus sessions & profile and merge into local storage
  Future<Map<String, dynamic>?> fetchAndMergeCloudData(
    StorageService storageService,
  ) async {
    final user = currentUser;
    if (user == null) return null;

    try {
      // Fetch cloud profile
      final profileRes = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      // Fetch cloud sessions
      final List<dynamic> sessionsRes = await client
          .from('focus_sessions')
          .select()
          .eq('user_id', user.id)
          .order('date_time', ascending: false);

      final List<FocusSession> cloudSessions = [];
      for (var row in sessionsRes) {
        try {
          cloudSessions.add(
            FocusSession(
              id: row['id'],
              durationMinutes: row['duration_minutes'] ?? 0,
              targetDurationMinutes: row['target_duration_minutes'],
              dateTime: DateTime.parse(row['date_time']).toLocal(),
              isWin: row['is_win'] ?? true,
              sessionType: row['session_type'] == 'battle'
                  ? SessionType.battle
                  : SessionType.solo,
              opponentName: row['opponent_name'],
              opponentScore: row['opponent_score'],
            ),
          );
        } catch (_) {}
      }

      // Merge cloud sessions with local sessions without duplicate IDs
      final localSessions = await storageService.getHistory();
      final localIds = localSessions.map((s) => s.id).toSet();

      final List<FocusSession> merged = List.from(localSessions);
      for (var cs in cloudSessions) {
        if (!localIds.contains(cs.id)) {
          merged.add(cs);
        }
      }
      merged.sort((a, b) => b.dateTime.compareTo(a.dateTime));

      // Persist merged sessions
      for (var s in merged) {
        if (!localIds.contains(s.id)) {
          await storageService.saveSession(s);
        }
      }

      // Merge profile if present
      if (profileRes != null) {
        final cloudName = profileRes['display_name']?.toString();
        if (cloudName != null && cloudName.isNotEmpty) {
          await storageService.saveUserName(cloudName);
        }
        final cloudAvatar = profileRes['avatar_path']?.toString();
        if (cloudAvatar != null && cloudAvatar.isNotEmpty) {
          await storageService.saveUserAvatar(cloudAvatar);
        }
        final cloudGoal = profileRes['daily_goal_minutes'] as int?;
        if (cloudGoal != null && cloudGoal > 0) {
          await storageService.saveDailyGoalMinutes(cloudGoal);
        }
      }

      return {
        'profile': profileRes,
        'sessionsCount': merged.length,
      };
    } catch (e) {
      debugPrint('Error fetching and merging cloud data: $e');
      return null;
    }
  }
}
