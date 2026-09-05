import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lock_in/providers/theme_provider.dart';
import 'package:lock_in/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeProvider', () {
    test('defaults to light mode', () async {
      final themeProvider = ThemeProvider(storageService: StorageService());
      await pumpEventQueue();

      expect(themeProvider.themeMode, equals(ThemeMode.light));
      expect(themeProvider.themeModeString, equals('light'));
      expect(themeProvider.themeModeDisplayName, equals('Light Mode'));
    });

    test('can switch to dark mode and persists to storage', () async {
      final themeProvider = ThemeProvider(storageService: StorageService());
      await pumpEventQueue();

      await themeProvider.setThemeMode(ThemeMode.dark);

      expect(themeProvider.themeMode, equals(ThemeMode.dark));
      expect(themeProvider.themeModeString, equals('dark'));
      expect(themeProvider.themeModeDisplayName, equals('Dark Mode'));

      final stored = await StorageService().getThemeMode();
      expect(stored, equals('dark'));
    });

    test('can switch to system mode', () async {
      final themeProvider = ThemeProvider(storageService: StorageService());
      await pumpEventQueue();

      await themeProvider.setThemeMode(ThemeMode.system);

      expect(themeProvider.themeMode, equals(ThemeMode.system));
      expect(themeProvider.themeModeString, equals('system'));
      expect(themeProvider.themeModeDisplayName, equals('Follow System Settings'));

      final stored = await StorageService().getThemeMode();
      expect(stored, equals('system'));
    });

    test('loads saved theme mode from storage on startup', () async {
      SharedPreferences.setMockInitialValues({'focus_theme_mode': 'dark'});

      final themeProvider = ThemeProvider(storageService: StorageService());
      await pumpEventQueue();

      expect(themeProvider.themeMode, equals(ThemeMode.dark));
    });

    test('setThemeModeFromString sets and saves correctly', () async {
      final themeProvider = ThemeProvider(storageService: StorageService());
      await pumpEventQueue();

      await themeProvider.setThemeModeFromString('dark');
      expect(themeProvider.themeMode, equals(ThemeMode.dark));

      await themeProvider.setThemeModeFromString('system');
      expect(themeProvider.themeMode, equals(ThemeMode.system));

      await themeProvider.setThemeModeFromString('light');
      expect(themeProvider.themeMode, equals(ThemeMode.light));
    });
  });
}
