import 'json_utils.dart';
import 'user_model.dart';

enum AdminAccessLevel {
  departmental('departmental', 'Departmental'),
  faculty('faculty', 'Faculty'),
  system('system', 'System');

  const AdminAccessLevel(this.value, this.label);

  final String value;
  final String label;

  static AdminAccessLevel fromJson(Object? value) =>
      AdminAccessLevel.values.firstWhere(
        (e) => e.value == value,
        orElse: () => AdminAccessLevel.departmental,
      );
}

class AdminModel {
  const AdminModel({
    required this.user,
    required this.adminId,
    required this.accessLevel,
    this.jobTitle,
    this.permissions = const [],
    this.twoFactorEnabled = true,
    this.lastLoginAt,
  });

  final UserModel user;

  /// Institutional administrator ID, e.g. `ADM-9021-SYS`.
  final String adminId;
  final AdminAccessLevel accessLevel;
  final String? jobTitle;
  final List<String> permissions;
  final bool twoFactorEnabled;
  final DateTime? lastLoginAt;

  String get id => user.id;

  factory AdminModel.fromJson(Json json) => AdminModel(
    user: UserModel.fromJson(JsonX.map(json['user'])),
    adminId: json['admin_id'] as String,
    accessLevel: AdminAccessLevel.fromJson(json['access_level']),
    jobTitle: json['job_title'] as String?,
    permissions: JsonX.stringList(json['permissions']),
    twoFactorEnabled: json['two_factor_enabled'] as bool? ?? true,
    lastLoginAt: JsonX.dateOrNull(json['last_login_at']),
  );

  Json toJson() => {
    'user': user.toJson(),
    'admin_id': adminId,
    'access_level': accessLevel.value,
    'job_title': jobTitle,
    'permissions': permissions,
    'two_factor_enabled': twoFactorEnabled,
    'last_login_at': JsonX.isoOrNull(lastLoginAt),
  };

  AdminModel copyWith({UserModel? user, bool? twoFactorEnabled}) => AdminModel(
    user: user ?? this.user,
    adminId: adminId,
    accessLevel: accessLevel,
    jobTitle: jobTitle,
    permissions: permissions,
    twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
    lastLoginAt: lastLoginAt,
  );
}

enum ActivitySeverity { info, success, warning, critical }

/// Entry of the administrative audit / activity feed.
class ActivityLogModel {
  const ActivityLogModel({
    required this.id,
    required this.title,
    required this.description,
    required this.timestamp,
    this.actorName,
    this.severity = ActivitySeverity.info,
    this.category,
  });

  final String id;
  final String title;
  final String description;
  final DateTime timestamp;
  final String? actorName;
  final ActivitySeverity severity;

  /// e.g. `users`, `courses`, `attendance`, `system`
  final String? category;

  factory ActivityLogModel.fromJson(Json json) => ActivityLogModel(
    id: json['id'].toString(),
    title: json['title'] as String,
    description: json['description'] as String? ?? '',
    timestamp: JsonX.date(json['timestamp']),
    actorName: json['actor_name'] as String?,
    severity: JsonX.enumByName(
      ActivitySeverity.values,
      json['severity'],
      ActivitySeverity.info,
    ),
    category: json['category'] as String?,
  );

  Json toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'timestamp': timestamp.toIso8601String(),
    'actor_name': actorName,
    'severity': severity.name,
    'category': category,
  };
}
