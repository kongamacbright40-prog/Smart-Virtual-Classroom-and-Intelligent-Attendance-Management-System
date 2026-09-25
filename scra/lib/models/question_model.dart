import 'json_utils.dart';

enum QuestionStatus {
  draft('draft', 'Draft'),
  active('active', 'Live'),
  closed('closed', 'Closed');

  const QuestionStatus(this.value, this.label);

  final String value;
  final String label;

  static QuestionStatus fromJson(Object? value) =>
      QuestionStatus.values.firstWhere(
        (e) => e.value == value,
        orElse: () => QuestionStatus.draft,
      );
}

class QuestionOption {
  const QuestionOption({
    required this.id,
    required this.label,
    required this.text,
    this.responseCount = 0,
  });

  final String id;

  /// Display key, e.g. `A`.
  final String label;
  final String text;
  final int responseCount;

  factory QuestionOption.fromJson(Json json) => QuestionOption(
        id: json['id'].toString(),
        label: json['label'] as String,
        text: json['text'] as String,
        responseCount: JsonX.toInt(json['response_count']),
      );

  Json toJson() => {
        'id': id,
        'label': label,
        'text': text,
        'response_count': responseCount,
      };

  QuestionOption copyWith({int? responseCount}) => QuestionOption(
        id: id,
        label: label,
        text: text,
        responseCount: responseCount ?? this.responseCount,
      );
}

/// A multiple-choice live question launched by a lecturer.
class QuestionModel {
  const QuestionModel({
    required this.id,
    required this.sessionId,
    required this.text,
    required this.options,
    this.correctOptionId,
    this.durationSeconds,
    this.status = QuestionStatus.draft,
    this.topic,
    this.createdAt,
    this.launchedAt,
    this.expectedResponders = 0,
    this.countsTowardGrade = true,
  });

  final String id;
  final String sessionId;
  final String text;
  final List<QuestionOption> options;
  final String? correctOptionId;

  /// `null` means unlimited time.
  final int? durationSeconds;
  final QuestionStatus status;
  final String? topic;
  final DateTime? createdAt;
  final DateTime? launchedAt;
  final int expectedResponders;
  final bool countsTowardGrade;

  int get responseCount =>
      options.fold(0, (sum, o) => sum + o.responseCount);

  double get responseRate => expectedResponders == 0
      ? 0
      : (responseCount / expectedResponders * 100).clamp(0, 100);

  double percentFor(String optionId) {
    final total = responseCount;
    if (total == 0) return 0;
    final o = options.firstWhere((o) => o.id == optionId,
        orElse: () => const QuestionOption(id: '', label: '', text: ''));
    return o.responseCount / total * 100;
  }

  /// Remaining time at [now], or null for unlimited / not launched.
  Duration? remainingAt(DateTime now) {
    if (durationSeconds == null || launchedAt == null) return null;
    final end = launchedAt!.add(Duration(seconds: durationSeconds!));
    final left = end.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  factory QuestionModel.fromJson(Json json) => QuestionModel(
        id: json['id'].toString(),
        sessionId: json['session_id'].toString(),
        text: json['text'] as String,
        options: JsonX.list(json['options'], QuestionOption.fromJson),
        correctOptionId: json['correct_option_id'] as String?,
        durationSeconds: json['duration_seconds'] == null
            ? null
            : JsonX.toInt(json['duration_seconds']),
        status: QuestionStatus.fromJson(json['status']),
        topic: json['topic'] as String?,
        createdAt: JsonX.dateOrNull(json['created_at']),
        launchedAt: JsonX.dateOrNull(json['launched_at']),
        expectedResponders: JsonX.toInt(json['expected_responders']),
        countsTowardGrade: json['counts_toward_grade'] as bool? ?? true,
      );

  Json toJson() => {
        'id': id,
        'session_id': sessionId,
        'text': text,
        'options': options.map((o) => o.toJson()).toList(),
        'correct_option_id': correctOptionId,
        'duration_seconds': durationSeconds,
        'status': status.value,
        'topic': topic,
        'created_at': JsonX.isoOrNull(createdAt),
        'launched_at': JsonX.isoOrNull(launchedAt),
        'expected_responders': expectedResponders,
        'counts_toward_grade': countsTowardGrade,
      };

  QuestionModel copyWith({
    List<QuestionOption>? options,
    QuestionStatus? status,
    DateTime? launchedAt,
    int? expectedResponders,
  }) =>
      QuestionModel(
        id: id,
        sessionId: sessionId,
        text: text,
        options: options ?? this.options,
        correctOptionId: correctOptionId,
        durationSeconds: durationSeconds,
        status: status ?? this.status,
        topic: topic,
        createdAt: createdAt,
        launchedAt: launchedAt ?? this.launchedAt,
        expectedResponders: expectedResponders ?? this.expectedResponders,
        countsTowardGrade: countsTowardGrade,
      );
}
