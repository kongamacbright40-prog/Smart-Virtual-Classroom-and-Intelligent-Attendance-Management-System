import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../models/app_settings_model.dart';
import '../models/auth_session_model.dart';
import '../models/user_model.dart';

/// Low-level key/value persistence. Swappable so tests can run in memory and
/// so sensitive values can later move to secure storage.
abstract interface class KeyValueStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<bool?> getBool(String key);
  Future<void> setBool(String key, bool value);
  Future<void> remove(String key);
  Future<void> clear();
}

class SharedPreferencesStore implements KeyValueStore {
  SharedPreferencesStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<SharedPreferencesStore> create() async =>
      SharedPreferencesStore(await SharedPreferences.getInstance());

  @override
  Future<String?> getString(String key) async => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  @override
  Future<bool?> getBool(String key) async => _prefs.getBool(key);

  @override
  Future<void> setBool(String key, bool value) => _prefs.setBool(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);

  @override
  Future<void> clear() => _prefs.clear();
}

class InMemoryStore implements KeyValueStore {
  InMemoryStore([Map<String, Object>? initial]) : _data = {...?initial};

  final Map<String, Object> _data;

  @override
  Future<String?> getString(String key) async => _data[key] as String?;

  @override
  Future<void> setString(String key, String value) async => _data[key] = value;

  @override
  Future<bool?> getBool(String key) async => _data[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async => _data[key] = value;

  @override
  Future<void> remove(String key) async => _data.remove(key);

  @override
  Future<void> clear() async => _data.clear();
}

/// Typed access to everything the app persists locally. Screens and
/// providers never touch [KeyValueStore] keys directly.
class StorageService {
  StorageService(this._store);

  final KeyValueStore _store;

  // Onboarding
  Future<bool> isOnboardingCompleted() async =>
      await _store.getBool(StorageKeys.onboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted(bool value) =>
      _store.setBool(StorageKeys.onboardingCompleted, value);

  // Selected role
  Future<UserRole?> getSelectedRole() async =>
      UserRole.tryParse(await _store.getString(StorageKeys.selectedRole));

  Future<void> setSelectedRole(UserRole role) =>
      _store.setString(StorageKeys.selectedRole, role.value);

  // Remember me
  Future<bool> getRememberMe() async =>
      await _store.getBool(StorageKeys.rememberMe) ?? true;

  Future<void> setRememberMe(bool value) =>
      _store.setBool(StorageKeys.rememberMe, value);

  // Authentication
  Future<AuthSessionModel?> getSession() async {
    final token = await _store.getString(StorageKeys.authToken);
    final userJson = await _store.getString(StorageKeys.currentUser);
    if (token == null || userJson == null) return null;
    try {
      final user = UserModel.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
      return AuthSessionModel(
        user: user,
        accessToken: token,
        refreshToken: await _store.getString(StorageKeys.refreshToken),
      );
    } on Object {
      await clearSession();
      return null;
    }
  }

  Future<void> saveSession(AuthSessionModel session) async {
    await _store.setString(StorageKeys.authToken, session.accessToken);
    await _store.setString(
      StorageKeys.currentUser,
      jsonEncode(session.user.toJson()),
    );
    if (session.refreshToken != null) {
      await _store.setString(StorageKeys.refreshToken, session.refreshToken!);
    }
  }

  Future<void> updateUser(UserModel user) => _store.setString(
        StorageKeys.currentUser,
        jsonEncode(user.toJson()),
      );

  Future<String?> getAccessToken() => _store.getString(StorageKeys.authToken);

  Future<void> clearSession() async {
    await _store.remove(StorageKeys.authToken);
    await _store.remove(StorageKeys.refreshToken);
    await _store.remove(StorageKeys.currentUser);
  }

  // Preferences
  Future<AppSettingsModel> getSettings() async {
    final raw = await _store.getString(StorageKeys.appSettings);
    if (raw == null) return const AppSettingsModel();
    try {
      return AppSettingsModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } on Object {
      return const AppSettingsModel();
    }
  }

  Future<void> saveSettings(AppSettingsModel settings) => _store.setString(
        StorageKeys.appSettings,
        jsonEncode(settings.toJson()),
      );
}
