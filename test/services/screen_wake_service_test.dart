import 'package:flutter_test/flutter_test.dart';
import 'package:lock_in/services/screen_wake_service.dart';
import 'package:wakelock_plus_platform_interface/wakelock_plus_platform_interface.dart';

class FakeWakelockPlusPlatform extends WakelockPlusPlatformInterface {
  bool _mockEnabled = false;

  @override
  Future<void> toggle({required bool enable}) async {
    _mockEnabled = enable;
  }

  @override
  Future<bool> get enabled async => _mockEnabled;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final fakePlatform = FakeWakelockPlusPlatform();
  WakelockPlusPlatformInterface.instance = fakePlatform;

  group('ScreenWakeService Tests', () {
    setUp(() async {
      fakePlatform._mockEnabled = false;
      await ScreenWakeService.disable();
    });

    test('initial state is disabled', () {
      expect(ScreenWakeService.isEnabled, isFalse);
    });

    test('enable turns isEnabled to true and updates platform', () async {
      await ScreenWakeService.enable();
      expect(ScreenWakeService.isEnabled, isTrue);
      expect(await fakePlatform.enabled, isTrue);
    });

    test('disable turns isEnabled to false and updates platform', () async {
      await ScreenWakeService.enable();
      expect(ScreenWakeService.isEnabled, isTrue);

      await ScreenWakeService.disable();
      expect(ScreenWakeService.isEnabled, isFalse);
      expect(await fakePlatform.enabled, isFalse);
    });

    test('setEnabled toggles state correctly', () async {
      await ScreenWakeService.setEnabled(true);
      expect(ScreenWakeService.isEnabled, isTrue);
      expect(await fakePlatform.enabled, isTrue);

      await ScreenWakeService.setEnabled(false);
      expect(ScreenWakeService.isEnabled, isFalse);
      expect(await fakePlatform.enabled, isFalse);
    });
  });
}
