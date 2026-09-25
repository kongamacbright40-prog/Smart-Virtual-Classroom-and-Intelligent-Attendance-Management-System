import 'package:flutter/material.dart';

import '../core/errors/error_handler.dart';
import '../models/app_settings_model.dart';
import '../services/storage_service.dart';

/// Device preferences (theme, notification toggles, classroom defaults).
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._storage);

  final StorageService _storage;
  AppSettingsModel _settings = const AppSettingsModel();
  bool _loaded = false;

  AppSettingsModel get settings => _settings;
  ThemeMode get themeMode => _settings.themeMode;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    try {
      _settings = await _storage.getSettings();
    } on Object catch (e) {
      ErrorHandler.log(e);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> update(
    AppSettingsModel Function(AppSettingsModel) change,
  ) async {
    _settings = change(_settings);
    notifyListeners();
    try {
      await _storage.saveSettings(_settings);
    } on Object catch (e) {
      ErrorHandler.log(e);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      update((s) => s.copyWith(themeMode: mode));
}
