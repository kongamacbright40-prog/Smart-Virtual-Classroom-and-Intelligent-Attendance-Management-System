import 'json_utils.dart';

enum UserRole {
  student('student', 'Student'),
  lecturer('lecturer', 'Lecturer'),
  admin('admin', 'Admin');

  const UserRole(this.value, this.label);

  final String value;
  final String label;

  static UserRole fromJson(Object? value) => UserRole.values.firstWhere(
    (r) => r.value == value,
    orElse: () => UserRole.student,
  );

  static UserRole? tryParse(Object? value) {
    for (final r in UserRole.values) {
      if (r.value == value) return r;
    }
    return null;
  }
}

/// Base identity shared by students, lecturers and administrators.
class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.departmentId,
    this.departmentName,
    this.isActive = true,
    this.createdAt,
    this.lastActiveAt,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String? phone;
  final String? avatarUrl;
  final String? departmentId;
  final String? departmentName;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;

  String get firstName => fullName
      .replaceAll(RegExp(r'^(Dr|Prof|Mr|Mrs|Ms)\.?\s+'), '')
      .split(' ')
      .first;

  factory UserModel.fromJson(Json json) => UserModel(
    id: json['id'].toString(),
    fullName: json['full_name'] as String,
    email: json['email'] as String,
    role: UserRole.fromJson(json['role']),
    phone: json['phone'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    departmentId: json['department_id'] as String?,
    departmentName: json['department_name'] as String?,
    isActive: json['is_active'] as bool? ?? true,
    createdAt: JsonX.dateOrNull(json['created_at']),
    lastActiveAt: JsonX.dateOrNull(json['last_active_at']),
  );

  Json toJson() => {
    'id': id,
    'full_name': fullName,
    'email': email,
    'role': role.value,
    'phone': phone,
    'avatar_url': avatarUrl,
    'department_id': departmentId,
    'department_name': departmentName,
    'is_active': isActive,
    'created_at': JsonX.isoOrNull(createdAt),
    'last_active_at': JsonX.isoOrNull(lastActiveAt),
  };

  UserModel copyWith({
    String? fullName,
    String? email,
    UserRole? role,
    String? phone,
    String? avatarUrl,
    String? departmentId,
    String? departmentName,
    bool? isActive,
    DateTime? lastActiveAt,
  }) => UserModel(
    id: id,
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    role: role ?? this.role,
    phone: phone ?? this.phone,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    departmentId: departmentId ?? this.departmentId,
    departmentName: departmentName ?? this.departmentName,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt,
    lastActiveAt: lastActiveAt ?? this.lastActiveAt,
  );

  @override
  bool operator ==(Object other) =>
      other is UserModel &&
      other.id == id &&
      other.fullName == fullName &&
      other.email == email &&
      other.role == role &&
      other.phone == phone &&
      other.isActive == isActive;

  @override
  int get hashCode => Object.hash(id, fullName, email, role, phone, isActive);
}
