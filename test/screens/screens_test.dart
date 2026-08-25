import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lock_in/providers/timer_provider.dart';
import 'package:lock_in/screens/home_screen.dart';
import 'package:lock_in/screens/battles_screen.dart';
import 'package:lock_in/screens/duration_screen.dart';
import 'package:lock_in/screens/profile_screen.dart';
import 'package:lock_in/screens/history_screen.dart';
import 'package:lock_in/screens/result_screen.dart';

Widget createTestApp(Widget child) {
  return ChangeNotifierProvider(
    create: (_) => TimerProvider(),
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
  });
}
