import 'package:flutter/foundation.dart';

import '../../../core/errors/error_handler.dart';
import '../../../models/models.dart';
import '../../../repositories/repositories.dart';
import '../../../services/auth_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/storage_service.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

/// Application-level authentication state.
///
/// Screens call these methods and read [status], [user], [isBusy] and
/// [errorMessage]; they never talk to repositories for auth directly.
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required this._repository,
    required this._authService,
    required this._storage,
    NotificationService? notificationService,
  }) : _notifications = notificationService;

  final AuthRepository _repository;
  final AuthService _authService;
  final StorageService _storage;
  final NotificationService? _notifications;

  AuthStatus _status = AuthStatus.unknown;
  bool _isBusy = false;
  String? _errorMessage;
  bool _onboardingCompleted = false;
  UserRole? _selectedRole;
  bool _rememberMe = true;

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;
  bool get onboardingCompleted => _onboardingCompleted;
  UserRole? get selectedRole => _selectedRole;
  bool get rememberMe => _rememberMe;
  UserModel? get user => _authService.currentUser;
  UserRole? get role => user?.role;

  /// Loads persisted onboarding / session state. Called by the splash screen.
  Future<void> bootstrap() async {
    try {
      _onboardingCompleted = await _storage.isOnboardingCompleted();
      _selectedRole = await _storage.getSelectedRole();
      _rememberMe = await _storage.getRememberMe();
      final session = await _authService.restore();
      _status = session == null
          ? AuthStatus.unauthenticated
          : AuthStatus.authenticated;
      if (session != null) {
        await _notifications?.startListening(session.user.id);
      }
    } on Object catch (e) {
      ErrorHandler.log(e);
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _onboardingCompleted = true;
    notifyListeners();
    await _storage.setOnboardingCompleted(true);
  }

  Future<void> selectRole(UserRole role) async {
    _selectedRole = role;
    notifyListeners();
    await _storage.setSelectedRole(role);
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      return true;
    } on Object catch (e) {
      _errorMessage = ErrorHandler.message(e);
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _startSession(AuthSessionModel session, bool persist) async {
    await _authService.start(session, persist: persist);
    _selectedRole = session.role;
    _rememberMe = persist;
    _status = AuthStatus.authenticated;
    await _notifications?.startListening(session.user.id);
  }

  Future<bool> login({
    required UserRole role,
    required String identifier,
    required String password,
    bool rememberMe = true,
  }) => _run(() async {
    final session = await _repository.login(
      role: role,
      identifier: identifier.trim(),
      password: password,
    );
    await _startSession(session, rememberMe);
  });

  Future<bool> register({
    required UserRole role,
    required String fullName,
    required String email,
    String? phone,
    required String identifier,
    required String password,
    String? departmentId,
    String? adminCode,
  }) => _run(() async {
    final session = await _repository.register(
      role: role,
      fullName: fullName.trim(),
      email: email.trim(),
      phone: phone,
      identifier: identifier.trim().toUpperCase(),
      password: password,
      departmentId: departmentId,
      adminCode: adminCode,
    );
    await _startSession(session, true);
  });

  Future<bool> requestPasswordReset(String email) =>
      _run(() => _repository.requestPasswordReset(email.trim()));

  Future<bool> verifyResetCode(String email, String code) =>
      _run(() => _repository.verifyResetCode(email: email.trim(), code: code));

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) => _run(
    () => _repository.resetPassword(
      email: email.trim(),
      code: code,
      newPassword: newPassword,
    ),
  );

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _run(
    () => _repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    ),
  );

  /// Updates the cached user after a profile edit.
  Future<void> updateUser(UserModel updated) async {
    await _authService.updateUser(updated);
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } on Object catch (e) {
      // Logging out locally must succeed even if the server call fails.
      ErrorHandler.log(e);
    }
    await _notifications?.stopListening();
    await _authService.clear();
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    notifyListeners();
  }

  /// Called when the API reports the token is no longer valid.
  Future<void> handleSessionExpired() async {
    if (!isAuthenticated) return;
    await _authService.clear();
    _status = AuthStatus.unauthenticated;
    _errorMessage = 'Your session has expired. Please sign in again.';
    notifyListeners();
  }
}
