import '../models/auth_session_model.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

/// Owns the authenticated session: keeps it in memory, persists it (when
/// "remember me" is on) and exposes the access token to [ApiService].
class AuthService {
  AuthService(this._storage);

  final StorageService _storage;
  AuthSessionModel? _session;

  AuthSessionModel? get session => _session;
  UserModel? get currentUser => _session?.user;
  bool get isAuthenticated => _session != null;

  /// Token provider passed to [ApiService].
  Future<String?> accessToken() async => _session?.accessToken;

  /// Restores a persisted session on app start.
  Future<AuthSessionModel?> restore() async {
    final stored = await _storage.getSession();
    if (stored == null || stored.isExpiredAt(DateTime.now())) {
      await _storage.clearSession();
      return null;
    }
    _session = stored;
    return stored;
  }

  Future<void> start(AuthSessionModel session, {bool persist = true}) async {
    _session = session;
    await _storage.setSelectedRole(session.role);
    await _storage.setRememberMe(persist);
    if (persist) {
      await _storage.saveSession(session);
    } else {
      await _storage.clearSession();
    }
  }

  Future<void> updateUser(UserModel user) async {
    final current = _session;
    if (current == null) return;
    _session = AuthSessionModel(
      user: user,
      accessToken: current.accessToken,
      refreshToken: current.refreshToken,
      expiresAt: current.expiresAt,
    );
    if (await _storage.getRememberMe()) await _storage.updateUser(user);
  }

  Future<void> clear() async {
    _session = null;
    await _storage.clearSession();
  }
}
