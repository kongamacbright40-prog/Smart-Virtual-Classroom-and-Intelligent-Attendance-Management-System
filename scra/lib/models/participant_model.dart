import 'json_utils.dart';
import 'user_model.dart';

/// A person currently connected to a live classroom.
class ParticipantModel {
  const ParticipantModel({
    required this.userId,
    required this.name,
    required this.role,
    required this.joinedAt,
    this.isMuted = true,
    this.isVideoOn = false,
    this.isHandRaised = false,
    this.isSpeaking = false,
    this.isScreenSharing = false,
    this.connectionQuality = 1,
  });

  final String userId;
  final String name;
  final UserRole role;
  final DateTime joinedAt;
  final bool isMuted;
  final bool isVideoOn;
  final bool isHandRaised;
  final bool isSpeaking;
  final bool isScreenSharing;

  /// 0 (poor) .. 1 (excellent).
  final double connectionQuality;

  bool get isLecturer => role == UserRole.lecturer;

  factory ParticipantModel.fromJson(Json json) => ParticipantModel(
        userId: json['user_id'].toString(),
        name: json['name'] as String,
        role: UserRole.fromJson(json['role']),
        joinedAt: JsonX.date(json['joined_at']),
        isMuted: json['is_muted'] as bool? ?? true,
        isVideoOn: json['is_video_on'] as bool? ?? false,
        isHandRaised: json['is_hand_raised'] as bool? ?? false,
        isSpeaking: json['is_speaking'] as bool? ?? false,
        isScreenSharing: json['is_screen_sharing'] as bool? ?? false,
        connectionQuality: JsonX.toDouble(json['connection_quality'], 1),
      );

  Json toJson() => {
        'user_id': userId,
        'name': name,
        'role': role.value,
        'joined_at': joinedAt.toIso8601String(),
        'is_muted': isMuted,
        'is_video_on': isVideoOn,
        'is_hand_raised': isHandRaised,
        'is_speaking': isSpeaking,
        'is_screen_sharing': isScreenSharing,
        'connection_quality': connectionQuality,
      };

  ParticipantModel copyWith({
    bool? isMuted,
    bool? isVideoOn,
    bool? isHandRaised,
    bool? isSpeaking,
    bool? isScreenSharing,
  }) =>
      ParticipantModel(
        userId: userId,
        name: name,
        role: role,
        joinedAt: joinedAt,
        isMuted: isMuted ?? this.isMuted,
        isVideoOn: isVideoOn ?? this.isVideoOn,
        isHandRaised: isHandRaised ?? this.isHandRaised,
        isSpeaking: isSpeaking ?? this.isSpeaking,
        isScreenSharing: isScreenSharing ?? this.isScreenSharing,
        connectionQuality: connectionQuality,
      );
}
