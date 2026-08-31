import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lock_in/models/focus_session.dart';
import 'package:lock_in/providers/battle_provider.dart';
import 'package:lock_in/providers/timer_provider.dart';
import 'package:lock_in/screens/battle_result_screen.dart';
import 'package:lock_in/screens/battles_screen.dart';
import 'package:lock_in/services/battle_realtime_data_source.dart';
import 'package:lock_in/services/battle_remote_data_source.dart';
import 'package:lock_in/services/battle_repository.dart';
import 'package:lock_in/services/storage_service.dart';
import 'package:lock_in/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StorageService storage;
  late BattleRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = StorageService();
    repository = BattleRepository(
      storageService: storage,
      remoteDataSource: MockBattleRemoteDataSource(),
      realtimeDataSource: MockBattleRealtimeDataSource(),
    );
  });

  Widget createTestWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerProvider()),
        ChangeNotifierProvider(
          create: (_) =>
              BattleProvider(repository: repository, storageService: storage),
        ),
      ],
      child: MaterialApp(theme: AppTheme.lightTheme, home: child),
    );
  }

  testWidgets('BattlesScreen renders action cards for Create and Join', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget(const BattlesScreen()));
    await tester.pumpAndSettle();

    expect(find.text('FOCUS BATTLES'), findsOneWidget);
    expect(find.text('Create Battle'), findsOneWidget);
    expect(find.text('Join Battle'), findsOneWidget);
  });

  testWidgets('Tapping Create Battle opens CreateBattleModal', (tester) async {
    await tester.pumpWidget(createTestWidget(const BattlesScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create Battle'));
    await tester.pumpAndSettle();

    expect(find.text('Create Focus Battle'), findsOneWidget);
    expect(find.text('Create Room Code'), findsOneWidget);
  });

  testWidgets('Tapping Join Battle opens JoinBattleModal', (tester) async {
    await tester.pumpWidget(createTestWidget(const BattlesScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Join Battle'));
    await tester.pumpAndSettle();

    expect(find.text('Join Focus Battle'), findsOneWidget);
    expect(find.text('ROOM CODE'), findsOneWidget);
    expect(find.text('Join Battle Room'), findsOneWidget);
  });

  testWidgets('BattleResultScreen refreshes TimerProvider on Return to Home', (
    tester,
  ) async {
    final timerProvider = TimerProvider();
    await timerProvider.refreshFromStorage();
    expect(timerProvider.todayFocusMinutes, 0);

    final battleProvider = BattleProvider(
      repository: repository,
      storageService: storage,
    );

    // Save a completed 60m battle session into storage
    final session = FocusSession(
      id: 'test-battle-1h',
      durationMinutes: 60,
      targetDurationMinutes: 60,
      dateTime: DateTime.now(),
      isWin: true,
      sessionType: SessionType.battle,
      opponentName: 'Alex',
      opponentScore: 'Victory',
    );
    await storage.saveSession(session);

    // Before Return to Home, in-memory timerProvider is still at 0 mins
    expect(timerProvider.todayFocusMinutes, 0);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: timerProvider),
          ChangeNotifierProvider.value(value: battleProvider),
        ],
        child: const MaterialApp(
          home: BattleResultScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Return to Home'), findsOneWidget);
    await tester.tap(find.text('Return to Home'));
    await tester.pumpAndSettle();

    // After return to home, TimerProvider has reloaded from storage immediately
    expect(timerProvider.todayFocusMinutes, 60);
    expect(timerProvider.history.length, 1);
    expect(timerProvider.history.first.sessionType, SessionType.battle);
    expect(timerProvider.history.first.opponentName, 'Alex');
  });
}
