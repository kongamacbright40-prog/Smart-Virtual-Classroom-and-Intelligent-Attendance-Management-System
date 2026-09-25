import 'package:flutter/material.dart' show ThemeMode;

import 'json_utils.dart';

/// Per-device user preferences (Student Settings screen and equivalents).
class AppSettingsModel {
  const AppSettingsModel({
    this.themeMode = ThemeMode.light,
    this.pushNotifications = true,
    this.emailClassAlerts = true,
    this.attendanceWarningGuard = true,
    this.attendanceWarningThreshold = 85,
    this.joinWithMicOff = true,
    this.joinWithCameraOff = false,
    this.noiseCancellation = 'High',
    this.biometricAttendanceLock = true,
    this.classReminders = true,
    this.liveQuestionAlerts = true,
    this.announcementAlerts = true,
  });

  final ThemeMode themeMode;
  final bool pushNotifications;
  final bool emailClassAlerts;
  final bool attendanceWarningGuard;
  final double attendanceWarningThreshold;
  final bool joinWithMicOff;
  final bool joinWithCameraOff;

  /// `Off`, `Low`, `High`
  final String noiseCancellation;
  final bool biometricAttendanceLock;
  final bool classReminders;
  final bool liveQuestionAlerts;
  final bool announcementAlerts;

  factory AppSettingsModel.fromJson(Json json) => AppSettingsModel(
    themeMode: JsonX.enumByName(
      ThemeMode.values,
      json['theme_mode'],
      ThemeMode.light,
    ),
    pushNotifications: json['push_notifications'] as bool? ?? true,
    emailClassAlerts: json['email_class_alerts'] as bool? ?? true,
    attendanceWarningGuard: json['attendance_warning_guard'] as bool? ?? true,
    attendanceWarningThreshold: JsonX.toDouble(
      json['attendance_warning_threshold'],
      85,
    ),
    joinWithMicOff: json['join_with_mic_off'] as bool? ?? true,
    joinWithCameraOff: json['join_with_camera_off'] as bool? ?? false,
    noiseCancellation: json['noise_cancellation'] as String? ?? 'High',
    biometricAttendanceLock: json['biometric_attendance_lock'] as bool? ?? true,
    classReminders: json['class_reminders'] as bool? ?? true,
    liveQuestionAlerts: json['live_question_alerts'] as bool? ?? true,
    announcementAlerts: json['announcement_alerts'] as bool? ?? true,
  );

  Json toJson() => {
    'theme_mode': themeMode.name,
    'push_notifications': pushNotifications,
    'email_class_alerts': emailClassAlerts,
    'attendance_warning_guard': attendanceWarningGuard,
    'attendance_warning_threshold': attendanceWarningThreshold,
    'join_with_mic_off': joinWithMicOff,
    'join_with_camera_off': joinWithCameraOff,
    'noise_cancellation': noiseCancellation,
    'biometric_attendance_lock': biometricAttendanceLock,
    'class_reminders': classReminders,
    'live_question_alerts': liveQuestionAlerts,
    'announcement_alerts': announcementAlerts,
  };

  AppSettingsModel copyWith({
    ThemeMode? themeMode,
    bool? pushNotifications,
    bool? emailClassAlerts,
    bool? attendanceWarningGuard,
    double? attendanceWarningThreshold,
    bool? joinWithMicOff,
    bool? joinWithCameraOff,
    String? noiseCancellation,
    bool? biometricAttendanceLock,
    bool? classReminders,
    bool? liveQuestionAlerts,
    bool? announcementAlerts,
  }) => AppSettingsModel(
    themeMode: themeMode ?? this.themeMode,
    pushNotifications: pushNotifications ?? this.pushNotifications,
    emailClassAlerts: emailClassAlerts ?? this.emailClassAlerts,
    attendanceWarningGuard:
        attendanceWarningGuard ?? this.attendanceWarningGuard,
    attendanceWarningThreshold:
        attendanceWarningThreshold ?? this.attendanceWarningThreshold,
    joinWithMicOff: joinWithMicOff ?? this.joinWithMicOff,
    joinWithCameraOff: joinWithCameraOff ?? this.joinWithCameraOff,
    noiseCancellation: noiseCancellation ?? this.noiseCancellation,
    biometricAttendanceLock:
        biometricAttendanceLock ?? this.biometricAttendanceLock,
    classReminders: classReminders ?? this.classReminders,
    liveQuestionAlerts: liveQuestionAlerts ?? this.liveQuestionAlerts,
    announcementAlerts: announcementAlerts ?? this.announcementAlerts,
  );
}

/// Institution-wide policies managed from the admin System Settings screen.
class SystemSettingsModel {
  const SystemSettingsModel({
    this.lateThresholdMinutes = 15,
    this.autoJoinLeaveRecording = true,
    this.participationWeight = 20,
    this.strictGeofencing = false,
    this.sessionTimeoutMinutes = 30,
    this.enforceSso = true,
    this.minimumAttendance = 75,
    this.clusterVersion = 'v2.4.1',
    this.lastSyncedAt,
  });

  final int lateThresholdMinutes;
  final bool autoJoinLeaveRecording;

  /// Weight (%) of live Q&A and chat in the participation score.
  final int participationWeight;
  final bool strictGeofencing;
  final int sessionTimeoutMinutes;
  final bool enforceSso;
  final double minimumAttendance;
  final String clusterVersion;
  final DateTime? lastSyncedAt;

  factory SystemSettingsModel.fromJson(Json json) => SystemSettingsModel(
    lateThresholdMinutes: JsonX.toInt(json['late_threshold_minutes'], 15),
    autoJoinLeaveRecording: json['auto_join_leave_recording'] as bool? ?? true,
    participationWeight: JsonX.toInt(json['participation_weight'], 20),
    strictGeofencing: json['strict_geofencing'] as bool? ?? false,
    sessionTimeoutMinutes: JsonX.toInt(json['session_timeout_minutes'], 30),
    enforceSso: json['enforce_sso'] as bool? ?? true,
    minimumAttendance: JsonX.toDouble(json['minimum_attendance'], 75),
    clusterVersion: json['cluster_version'] as String? ?? 'v2.4.1',
    lastSyncedAt: JsonX.dateOrNull(json['last_synced_at']),
  );

  Json toJson() => {
    'late_threshold_minutes': lateThresholdMinutes,
    'auto_join_leave_recording': autoJoinLeaveRecording,
    'participation_weight': participationWeight,
    'strict_geofencing': strictGeofencing,
    'session_timeout_minutes': sessionTimeoutMinutes,
    'enforce_sso': enforceSso,
    'minimum_attendance': minimumAttendance,
    'cluster_version': clusterVersion,
    'last_synced_at': JsonX.isoOrNull(lastSyncedAt),
  };

  SystemSettingsModel copyWith({
    int? lateThresholdMinutes,
    bool? autoJoinLeaveRecording,
    int? participationWeight,
    bool? strictGeofencing,
    int? sessionTimeoutMinutes,
    bool? enforceSso,
    double? minimumAttendance,
  }) => SystemSettingsModel(
    lateThresholdMinutes: lateThresholdMinutes ?? this.lateThresholdMinutes,
    autoJoinLeaveRecording:
        autoJoinLeaveRecording ?? this.autoJoinLeaveRecording,
    participationWeight: participationWeight ?? this.participationWeight,
    strictGeofencing: strictGeofencing ?? this.strictGeofencing,
    sessionTimeoutMinutes: sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
    enforceSso: enforceSso ?? this.enforceSso,
    minimumAttendance: minimumAttendance ?? this.minimumAttendance,
    clusterVersion: clusterVersion,
    lastSyncedAt: lastSyncedAt,
  );
}
