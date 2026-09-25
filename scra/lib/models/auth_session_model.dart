import 'json_utils.dart';
import 'user_model.dart';

/// Authenticated session returned by the backend after login.
class AuthSessionModel {
  const AuthSessionModel({
    required this.user,
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  final UserModel user;
  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  UserRole get role => user.role;

  bool isExpiredAt(DateTime now) =>
      expiresAt != null && now.isAfter(expiresAt!);

  factory AuthSessionModel.fromJson(Json json) => AuthSessionModel(
        user: UserModel.fromJson(JsonX.map(json['user'])),
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String?,
        expiresAt: JsonX.dateOrNull(json['expires_at']),
      );

  Json toJson() => {
        'user': user.toJson(),
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_at': JsonX.isoOrNull(expiresAt),
      };
}
