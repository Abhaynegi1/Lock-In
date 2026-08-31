import 'package:flutter_test/flutter_test.dart';
import 'package:lock_in/config/app_config.dart';
import 'package:lock_in/models/battle_event.dart';
import 'package:lock_in/services/battle_realtime_data_source.dart';
import 'package:lock_in/services/websocket_battle_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebSocketBattleDataSource Unit Tests', () {
    late WebSocketBattleDataSource dataSource;

    setUp(() {
      dataSource = WebSocketBattleDataSource();
    });

    tearDown(() {
      dataSource.dispose();
    });

    test('initializes with disconnected state and valid default URLs', () {
      expect(
        dataSource.connectionState,
        BattleConnectionState.disconnected,
      );
      expect(
        WebSocketBattleDataSource.productionServerUrl,
        AppConfig.battleServerUrl,
      );
      expect(
        WebSocketBattleDataSource.activeServerUrl,
        AppConfig.battleServerUrl,
      );
    });

    test('disconnect resets connection state to disconnected', () async {
      await dataSource.disconnect();
      expect(
        dataSource.connectionState,
        BattleConnectionState.disconnected,
      );
    });

    test('exposes active eventStream and connectionStateStream', () async {
      expect(dataSource.eventStream, isA<Stream<BattleEvent>>());
      expect(
        dataSource.connectionStateStream,
        isA<Stream<BattleConnectionState>>(),
      );

      final stateEvents = <BattleConnectionState>[];
      final subscription = dataSource.connectionStateStream.listen(
        stateEvents.add,
      );

      await dataSource.disconnect();
      await subscription.cancel();
    });

    test('allows updating activeServerUrl for local or custom testing', () {
      const customUrl = 'ws://127.0.0.1:8080';
      WebSocketBattleDataSource.activeServerUrl = customUrl;
      expect(WebSocketBattleDataSource.activeServerUrl, customUrl);

      // Restore to default
      WebSocketBattleDataSource.activeServerUrl = AppConfig.battleServerUrl;
      expect(
        WebSocketBattleDataSource.activeServerUrl,
        AppConfig.battleServerUrl,
      );
    });
  });
}
