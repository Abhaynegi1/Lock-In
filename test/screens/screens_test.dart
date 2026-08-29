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

Widget createTestApp(Widget child, {TimerProvider? timerProvider}) {
  return MultiProvider(
    providers: [
      if (timerProvider != null)
        ChangeNotifierProvider<TimerProvider>.value(value: timerProvider)
      else
        ChangeNotifierProvider(create: (_) => TimerProvider()),
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

    testWidgets('ProfileScreen renders user profile settings', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Dev User'), findsOneWidget);
      expect(find.text('PERSONAL STATS'), findsOneWidget);
      expect(find.text('PREFERENCES'), findsOneWidget);
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
