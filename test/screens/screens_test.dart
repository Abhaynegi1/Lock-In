import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lock_in/providers/auth_provider.dart';
import 'package:lock_in/providers/battle_provider.dart';
import 'package:lock_in/providers/timer_provider.dart';
import 'package:lock_in/screens/home_screen.dart';
import 'package:lock_in/screens/battles_screen.dart';
import 'package:lock_in/screens/duration_screen.dart';
import 'package:lock_in/screens/profile_screen.dart';
import 'package:lock_in/screens/history_screen.dart';
import 'package:lock_in/screens/result_screen.dart';

import 'package:lock_in/providers/theme_provider.dart';
import 'package:lock_in/services/storage_service.dart';

Widget createTestApp(
  Widget child, {
  TimerProvider? timerProvider,
  ThemeProvider? themeProvider,
}) {
  return MultiProvider(
    providers: [
      if (timerProvider != null)
        ChangeNotifierProvider<TimerProvider>.value(value: timerProvider)
      else
        ChangeNotifierProvider(create: (_) => TimerProvider()),
      if (themeProvider != null)
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider)
      else
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider(create: (_) => BattleProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
    ],
    child: MaterialApp(home: child),
  );
}


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'focus_streak': 5,
      'focus_daily_goal': 240,
      'focus_username': 'Dev User',
      'focus_theme_mode': 'light',
    });
  });

  group('Screen Widget Tests', () {
    testWidgets('HomeScreen renders key UI elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(const HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('LOCK IN'), findsOneWidget);
      expect(find.text('SOLO FOCUS'), findsOneWidget);
      expect(find.text('Start focus'), findsOneWidget);
    });

    testWidgets('DurationScreen renders preset duration options', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(const DurationScreen()));
      await tester.pumpAndSettle();

      expect(find.text('SELECT DURATION'), findsOneWidget);
      expect(find.text('Start focus'), findsOneWidget);
      expect(find.text('Choose your focus block.'), findsOneWidget);
    });

    testWidgets('BattlesScreen renders header and title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(const BattlesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('FOCUS BATTLES'), findsOneWidget);
      expect(find.text('Friendly accountability.'), findsOneWidget);
    });

    testWidgets('ProfileScreen renders user profile settings and opens Appearance modal', (
      WidgetTester tester,
    ) async {
      final themeProvider = ThemeProvider(storageService: StorageService());
      await themeProvider.setThemeMode(ThemeMode.light);

      await tester.pumpWidget(
        createTestApp(const ProfileScreen(), themeProvider: themeProvider),
      );
      await tester.pump();

      expect(find.text('Dev User'), findsOneWidget);
      expect(find.text('PERSONAL STATS'), findsOneWidget);
      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Light Mode · Warm paper'), findsOneWidget);

      // Scroll and tap Appearance setting tile to open modal
      await tester.ensureVisible(find.text('Appearance'));
      await tester.pump();
      await tester.tap(find.text('Appearance'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify modal options are displayed
      expect(find.text('Choose your preferred theme or match your device settings:'), findsOneWidget);
      expect(find.text('Light Mode'), findsWidgets);
      expect(find.text('Dark Mode'), findsWidgets);
      expect(find.text('Follow System Settings'), findsOneWidget);

      // Tap Dark Mode option in modal
      await tester.tap(find.text('Dark Mode').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(themeProvider.themeMode, equals(ThemeMode.dark));
      expect(find.text('Dark Mode · Deep slate'), findsOneWidget);
    });

    testWidgets('HistoryScreen renders history log header', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(const HistoryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('FOCUS LOG'), findsOneWidget);
      expect(find.text('Quiet momentum.'), findsOneWidget);
    });

    testWidgets('ResultScreen renders result UI correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(const ResultScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Session interrupted.'), findsOneWidget);
      expect(find.text('Back to Today'), findsOneWidget);
    });

    testWidgets('ResultScreen renders extend card when session won and defaults to 5m', (
      WidgetTester tester,
    ) async {
      final timerProvider = TimerProvider();
      timerProvider.setStatusForTesting(SessionStatus.won, totalSeconds: 1500);

      await tester.pumpWidget(
        createTestApp(const ResultScreen(), timerProvider: timerProvider),
      );
      await tester.pump();

      expect(find.text('Session completed.'), findsOneWidget);
      expect(find.text('EXTEND SESSION'), findsOneWidget);
      expect(find.text('+5 min'), findsOneWidget);
      expect(find.text('Extend session (+5m)'), findsOneWidget);

      // Tap '+' stepper button to adjust duration
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(find.text('+10 min'), findsOneWidget);
      expect(find.text('Extend session (+10m)'), findsOneWidget);

      // Tap '+15m' preset chip
      await tester.tap(find.text('+15m'));
      await tester.pump();
      expect(find.text('+15 min'), findsOneWidget);
      expect(find.text('Extend session (+15m)'), findsOneWidget);
    });

    testWidgets('ResultScreen renders reassurance banner when extension interrupted', (
      WidgetTester tester,
    ) async {
      final timerProvider = TimerProvider();
      timerProvider.setStatusForTesting(SessionStatus.won, totalSeconds: 1500);
      timerProvider.setExtensionInterruptedForTesting(true);

      await tester.pumpWidget(
        createTestApp(const ResultScreen(), timerProvider: timerProvider),
      );
      await tester.pump();

      expect(find.text('Session completed.'), findsOneWidget);
      expect(
        find.text(
          'Extension ended early. Your 25m session was safely recorded!',
        ),
        findsOneWidget,
      );
    });

  });
}
