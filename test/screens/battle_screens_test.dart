import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lock_in/providers/battle_provider.dart';
import 'package:lock_in/providers/timer_provider.dart';
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
          create: (_) => BattleProvider(
            repository: repository,
            storageService: storage,
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: child,
      ),
    );
  }

  testWidgets('BattlesScreen renders action cards for Create and Join', (tester) async {
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
}
