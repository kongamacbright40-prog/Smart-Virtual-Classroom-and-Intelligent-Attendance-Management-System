import 'json_utils.dart';

enum ResponseStatus {
  pending('pending', 'Sending'),
  submitted('submitted', 'Submitted'),
  synced('synced', 'Response Synced to Session'),
  failed('failed', 'Failed');

  const ResponseStatus(this.value, this.label);

  final String value;
  final String label;

  static ResponseStatus fromJson(Object? value) =>
      ResponseStatus.values.firstWhere(
        (e) => e.value == value,
        orElse: () => ResponseStatus.submitted,
      );
}

/// A student's answer to a [QuestionModel].
class QuestionResponseModel {
  const QuestionResponseModel({
    required this.id,
    required this.questionId,
    required this.studentId,
    required this.selectedOptionId,
    required this.submittedAt,
    this.status = ResponseStatus.submitted,
    this.isCorrect,
  });

  final String id;
  final String questionId;
  final String studentId;
  final String selectedOptionId;
  final DateTime submittedAt;
  final ResponseStatus status;

  /// Revealed once the lecturer broadcasts results.
  final bool? isCorrect;

  factory QuestionResponseModel.fromJson(Json json) => QuestionResponseModel(
        id: json['id'].toString(),
        questionId: json['question_id'].toString(),
        studentId: json['student_id'].toString(),
        selectedOptionId: json['selected_option_id'].toString(),
        submittedAt: JsonX.date(json['submitted_at']),
        status: ResponseStatus.fromJson(json['status']),
        isCorrect: json['is_correct'] as bool?,
      );

  Json toJson() => {
        'id': id,
        'question_id': questionId,
        'student_id': studentId,
        'selected_option_id': selectedOptionId,
        'submitted_at': submittedAt.toIso8601String(),
        'status': status.value,
        'is_correct': isCorrect,
      };

  QuestionResponseModel copyWith({ResponseStatus? status, bool? isCorrect}) =>
      QuestionResponseModel(
        id: id,
        questionId: questionId,
        studentId: studentId,
        selectedOptionId: selectedOptionId,
        submittedAt: submittedAt,
        status: status ?? this.status,
        isCorrect: isCorrect ?? this.isCorrect,
      );
}
