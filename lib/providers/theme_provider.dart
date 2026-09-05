import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider with ChangeNotifier {
  final StorageService _storageService;
  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider({StorageService? storageService})
      : _storageService = storageService ?? StorageService() {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  String get themeModeString {
    switch (_themeMode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.light:
        return 'light';
    }
  }

  String get themeModeDisplayName {
    switch (_themeMode) {
      case ThemeMode.dark:
        return 'Dark Mode';
      case ThemeMode.system:
        return 'Follow System Settings';
      case ThemeMode.light:
        return 'Light Mode';
    }
  }

  Future<void> _loadThemeMode() async {
    final savedMode = await _storageService.getThemeMode();
    _applyThemeModeFromString(savedMode, save: false);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _storageService.saveThemeMode(themeModeString);
  }

  Future<void> setThemeModeFromString(String modeStr) async {
    _applyThemeModeFromString(modeStr, save: true);
  }

  void _applyThemeModeFromString(String modeStr, {bool save = true}) {
    switch (modeStr) {
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'system':
        _themeMode = ThemeMode.system;
        break;
      case 'light':
      default:
        _themeMode = ThemeMode.light;
        break;
    }
    notifyListeners();
    if (save) {
      _storageService.saveThemeMode(modeStr);
    }
  }
}
