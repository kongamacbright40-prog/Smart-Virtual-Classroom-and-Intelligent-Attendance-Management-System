import 'dart:async';
import 'dart:math';

import '../../core/errors/app_exception.dart';
import '../../models/models.dart';
import '../repositories.dart';
import 'mock_data_store.dart';
import 'mock_repository_base.dart';

class MockQuestionRepository extends MockRepositoryBase
    implements QuestionRepository {
  MockQuestionRepository(
    this._store, {
    super.latency,
    this.simulateResponses = false,
  });

  final MockDataStore _store;

  /// When true, launched questions receive simulated student answers so the
  /// lecturer results view can be demonstrated without real students.
  final bool simulateResponses;
  final Map<String, Timer> _simulations = {};
  final Random _random = Random(7);

  QuestionModel? _active(String sessionId) {
    for (final q in _store.questions.values) {
      if (q.sessionId == sessionId && q.status == QuestionStatus.active) {
        return q;
      }
    }
    return null;
  }

  void _emit(String sessionId) =>
      _store.questionChannel(sessionId).add(_active(sessionId));

  QuestionModel _require(String id) {
    final q = _store.questions[id];
    if (q == null) throw const NotFoundException('Question not found.');
    return q;
  }

  @override
  Future<List<QuestionModel>> getSessionQuestions(String sessionId) => delay(
    () =>
        _store.questions.values.where((q) => q.sessionId == sessionId).toList()
          ..sort(
            (a, b) => (b.createdAt ?? DateTime(0)).compareTo(
              a.createdAt ?? DateTime(0),
            ),
          ),
  );

  QuestionModel _normalize(QuestionModel q, QuestionStatus status) {
    final id = q.id.isEmpty ? _store.nextId('q') : q.id;
    final options = [
      for (var i = 0; i < q.options.length; i++)
        QuestionOption(
          id: q.options[i].id.isEmpty
              ? '$id-${q.options[i].label}'
              : q.options[i].id,
          label: q.options[i].label,
          text: q.options[i].text,
        ),
    ];
    final correctIndex = q.options.indexWhere((o) => o.id == q.correctOptionId);
    return QuestionModel(
      id: id,
      sessionId: q.sessionId,
      text: q.text,
      options: options,
      correctOptionId: correctIndex >= 0 ? options[correctIndex].id : null,
      durationSeconds: q.durationSeconds,
      status: status,
      topic: q.topic,
      createdAt: q.createdAt ?? DateTime.now(),
      launchedAt: status == QuestionStatus.active ? DateTime.now() : null,
      expectedResponders: (_store.participants[q.sessionId] ?? const [])
          .where((p) => p.role == UserRole.student)
          .length,
      countsTowardGrade: q.countsTowardGrade,
    );
  }

  @override
  Future<QuestionModel> saveDraft(QuestionModel question) => delay(() {
    final draft = _normalize(question, QuestionStatus.draft);
    _store.questions[draft.id] = draft;
    return draft;
  });

  @override
  Future<QuestionModel> launchQuestion(QuestionModel question) => delay(() {
    final current = _active(question.sessionId);
    if (current != null && current.id != question.id) {
      _store.questions[current.id] = current.copyWith(
        status: QuestionStatus.closed,
      );
    }
    final launched = _normalize(question, QuestionStatus.active);
    _store.questions[launched.id] = launched;
    _emit(launched.sessionId);
    if (simulateResponses) _simulate(launched.id);
    return launched;
  });

  void _simulate(String questionId) {
    _simulations[questionId]?.cancel();
    _simulations[questionId] = Timer.periodic(
      const Duration(milliseconds: 900),
      (timer) {
        final q = _store.questions[questionId];
        if (q == null ||
            q.status != QuestionStatus.active ||
            q.responseCount >= (q.expectedResponders * 0.8).round()) {
          timer.cancel();
          return;
        }
        final correct = q.options.indexWhere((o) => o.id == q.correctOptionId);
        final pick = _random.nextDouble() < 0.7 && correct >= 0
            ? correct
            : _random.nextInt(q.options.length);
        final options = [
          for (var i = 0; i < q.options.length; i++)
            i == pick
                ? q.options[i].copyWith(
                    responseCount: q.options[i].responseCount + 1,
                  )
                : q.options[i],
        ];
        _store.questions[questionId] = q.copyWith(options: options);
        _emit(q.sessionId);
      },
    );
  }

  @override
  Future<QuestionModel> closeQuestion(String questionId) => delay(() {
    _simulations.remove(questionId)?.cancel();
    final closed = _require(questionId).copyWith(status: QuestionStatus.closed);
    _store.questions[questionId] = closed;
    _emit(closed.sessionId);
    return closed;
  });

  @override
  Future<QuestionModel> broadcastResults(String questionId) => delay(() {
    final q = _require(questionId);
    for (final entry in _store.responses.entries.toList()) {
      final r = entry.value;
      if (r.questionId == questionId) {
        _store.responses[entry.key] = r.copyWith(
          status: ResponseStatus.synced,
          isCorrect: r.selectedOptionId == q.correctOptionId,
        );
      }
    }
    final closed = q.copyWith(status: QuestionStatus.closed);
    _store.questions[questionId] = closed;
    _emit(q.sessionId);
    return closed;
  });

  @override
  Future<QuestionResponseModel> submitResponse({
    required String questionId,
    required String studentId,
    required String optionId,
  }) => delay(() {
    final q = _require(questionId);
    if (q.status != QuestionStatus.active) {
      throw const ValidationException(
        'This question is no longer accepting answers.',
      );
    }
    final remaining = q.remainingAt(DateTime.now());
    if (remaining != null && remaining == Duration.zero) {
      throw const ValidationException('Time is up for this question.');
    }
    final key = '$questionId:$studentId';
    if (_store.responses.containsKey(key)) {
      throw const ValidationException(
        'You have already answered this question.',
      );
    }
    if (!q.options.any((o) => o.id == optionId)) {
      throw const ValidationException('Select a valid answer.');
    }
    final response = QuestionResponseModel(
      id: _store.nextId('resp'),
      questionId: questionId,
      studentId: studentId,
      selectedOptionId: optionId,
      submittedAt: DateTime.now(),
      status: ResponseStatus.synced,
    );
    _store.responses[key] = response;
    _store.questions[questionId] = q.copyWith(
      options: [
        for (final o in q.options)
          o.id == optionId ? o.copyWith(responseCount: o.responseCount + 1) : o,
      ],
    );
    _emit(q.sessionId);
    return response;
  });

  @override
  Future<QuestionResponseModel?> getResponse({
    required String questionId,
    required String studentId,
  }) => delay(() => _store.responses['$questionId:$studentId']);

  @override
  Stream<QuestionModel?> watchActiveQuestion(String sessionId) async* {
    yield _active(sessionId);
    yield* _store.questionChannel(sessionId).stream;
  }

  void dispose() {
    for (final t in _simulations.values) {
      t.cancel();
    }
    _simulations.clear();
  }
}
