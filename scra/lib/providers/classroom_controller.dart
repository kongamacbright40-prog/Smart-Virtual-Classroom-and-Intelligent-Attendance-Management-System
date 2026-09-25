import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/constants/api_endpoints.dart';
import '../core/errors/error_handler.dart';
import '../models/models.dart';
import '../repositories/repositories.dart';
import '../services/webrtc_service.dart';
import '../services/websocket_service.dart';

/// State + actions for one live classroom session, shared by the student
/// and lecturer experiences (classroom, chat, questions, live attendance).
///
/// Realtime data arrives through repository streams (mock today, WebSocket
/// events tomorrow); audio/video through [WebRTCService].
class ClassroomController extends ChangeNotifier {
  ClassroomController({
    required this.sessionId,
    required this.user,
    required ClassroomRepository classroomRepository,
    required QuestionRepository questionRepository,
    required AttendanceRepository attendanceRepository,
    required ScheduleRepository scheduleRepository,
    required WebRTCService webRTCService,
    required WebSocketService webSocketService,
    this.joinWithMicOff = true,
    this.joinWithCameraOff = false,
  })  : _classroom = classroomRepository,
        _questions = questionRepository,
        _attendance = attendanceRepository,
        _schedule = scheduleRepository,
        _media = webRTCService,
        _socket = webSocketService;

  final String sessionId;
  final UserModel user;
  final bool joinWithMicOff;
  final bool joinWithCameraOff;

  final ClassroomRepository _classroom;
  final QuestionRepository _questions;
  final AttendanceRepository _attendance;
  final ScheduleRepository _schedule;
  final WebRTCService _media;
  final WebSocketService _socket;

  final List<StreamSubscription<Object?>> _subscriptions = [];

  ClassSessionModel? _session;
  bool _isLoading = true;
  bool _joined = false;
  bool _disposed = false;
  String? _errorMessage;
  List<ParticipantModel> _participants = const [];
  final List<ChatMessageModel> _messages = [];
  QuestionModel? _activeQuestion;
  QuestionModel? _lastQuestion;
  QuestionResponseModel? _myResponse;
  AttendanceRecordModel? _myAttendance;
  List<AttendanceRecordModel> _sessionAttendance = const [];
  RealtimeConnectionState _connection = RealtimeConnectionState.disconnected;
  MediaState _mediaState = const MediaState();
  bool _isSubmittingAnswer = false;
  bool _isEnding = false;

  bool get isLecturer => user.role == UserRole.lecturer;
  ClassSessionModel? get session => _session;
  bool get isLoading => _isLoading;
  bool get joined => _joined;
  String? get errorMessage => _errorMessage;
  List<ParticipantModel> get participants => _participants;
  List<ParticipantModel> get students =>
      _participants.where((p) => p.role == UserRole.student).toList();
  ParticipantModel? get lecturer {
    for (final p in _participants) {
      if (p.isLecturer) return p;
    }
    return null;
  }

  ParticipantModel? get me {
    for (final p in _participants) {
      if (p.userId == user.id) return p;
    }
    return null;
  }

  List<ChatMessageModel> get messages => List.unmodifiable(_messages);
  QuestionModel? get activeQuestion => _activeQuestion;

  /// Most recent question (active or just closed) for results views.
  QuestionModel? get lastQuestion => _activeQuestion ?? _lastQuestion;
  QuestionResponseModel? get myResponse => _myResponse;
  AttendanceRecordModel? get myAttendance => _myAttendance;
  List<AttendanceRecordModel> get sessionAttendance => _sessionAttendance;
  RealtimeConnectionState get connectionState => _connection;
  MediaState get mediaState => _mediaState;
  bool get micEnabled => _mediaState.microphoneEnabled;
  bool get cameraEnabled => _mediaState.cameraEnabled;
  bool get screenSharing => _mediaState.screenSharing;
  bool get handRaised => me?.isHandRaised ?? false;
  bool get isSubmittingAnswer => _isSubmittingAnswer;
  bool get isEnding => _isEnding;
  bool get isLive => _session?.status == SessionStatus.live;
  bool get attendanceActive => _session?.attendanceActive ?? false;
  int get participantCount => _participants.length;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Loads the session and joins it (media, realtime, attendance).
  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      _session = await _schedule.getSession(sessionId);
      if (isLecturer && _session!.status == SessionStatus.scheduled) {
        _session = await _classroom.startClass(sessionId);
      }
      if (!isLecturer && _session!.status != SessionStatus.live) {
        throw StateError('not live');
      }

      _subscriptions.add(_socket.stateChanges.listen((s) {
        _connection = s;
        _notify();
      }));
      await _socket.connect(ApiEndpoints.sessionEvents(sessionId));
      _connection = _socket.state;

      _subscriptions.add(_media.stateChanges.listen((s) {
        _mediaState = s;
        _notify();
      }));
      await _media.joinRoom(
        roomId: sessionId,
        userId: user.id,
        audio: isLecturer || !joinWithMicOff,
        video: isLecturer || !joinWithCameraOff,
      );
      _mediaState = _media.state;

      await _classroom.joinClass(sessionId, user);
      _joined = true;

      _subscriptions.add(
        _classroom.watchParticipants(sessionId).listen((list) {
          _participants = list;
          _notify();
        }),
      );

      _messages
        ..clear()
        ..addAll(await _classroom.getMessages(sessionId));
      _subscriptions.add(_classroom.watchMessages(sessionId).listen(_onMessage));

      _subscriptions.add(
        _questions.watchActiveQuestion(sessionId).listen(_onQuestion),
      );

      if (isLecturer) {
        _sessionAttendance = await _attendance.getSessionAttendance(sessionId);
        _subscriptions.add(
          _attendance.watchSessionAttendance(sessionId).listen((records) {
            _sessionAttendance = records;
            _notify();
          }),
        );
      } else if (attendanceActive) {
        _myAttendance =
            await _attendance.checkIn(sessionId: sessionId, studentId: user.id);
      }
    } on StateError {
      _errorMessage = 'This class is not live right now.';
    } on Object catch (e) {
      _errorMessage = ErrorHandler.message(e);
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  void _onMessage(ChatMessageModel message) {
    final i = _messages.indexWhere((m) => m.id == message.id);
    if (i == -1) {
      _messages.add(message);
    } else {
      _messages[i] = message;
    }
    _notify();
  }

  Future<void> _onQuestion(QuestionModel? q) async {
    if (q == null && _activeQuestion != null) {
      _lastQuestion = _activeQuestion;
    }
    final changed = q?.id != _activeQuestion?.id;
    _activeQuestion = q;
    if (q != null) _lastQuestion = q;
    if (changed && !isLecturer && q != null) {
      try {
        _myResponse =
            await _questions.getResponse(questionId: q.id, studentId: user.id);
      } on Object catch (e) {
        ErrorHandler.log(e);
      }
    }
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Media controls
  // ---------------------------------------------------------------------------

  Future<void> toggleMicrophone() async {
    final enabled = !micEnabled;
    await _media.setMicrophoneEnabled(enabled);
    await _safe(() => _classroom.updateMediaState(sessionId, user.id,
        isMuted: !enabled));
  }

  Future<void> toggleCamera() async {
    final enabled = !cameraEnabled;
    await _media.setCameraEnabled(enabled);
    await _safe(() =>
        _classroom.updateMediaState(sessionId, user.id, isVideoOn: enabled));
  }

  Future<void> toggleScreenShare() async {
    if (screenSharing) {
      await _media.stopScreenShare();
    } else {
      await _media.startScreenShare();
    }
    await _safe(() => _classroom.updateMediaState(sessionId, user.id,
        isScreenSharing: _media.state.screenSharing));
  }

  Future<void> toggleHand() =>
      _safe(() => _classroom.setHandRaised(sessionId, user.id, !handRaised));

  Future<void> lowerHand(String userId) =>
      _safe(() => _classroom.setHandRaised(sessionId, userId, false));

  // ---------------------------------------------------------------------------
  // Chat
  // ---------------------------------------------------------------------------

  Future<void> sendMessage(String text, {bool isQuestion = false}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final local = ChatMessageModel(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      classroomId: sessionId,
      senderId: user.id,
      senderName: user.fullName,
      senderRole: user.role,
      message: trimmed,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      isQuestion: isQuestion,
    );
    _messages.add(local);
    _notify();
    await _deliver(local);
  }

  Future<void> retryMessage(ChatMessageModel message) async {
    final i = _messages.indexWhere((m) => m.id == message.id);
    if (i == -1) return;
    _messages[i] = message.copyWith(status: MessageStatus.sending);
    _notify();
    await _deliver(_messages[i]);
  }

  Future<void> _deliver(ChatMessageModel local) async {
    try {
      final sent = await _classroom.sendMessage(local);
      final i = _messages.indexWhere((m) => m.id == local.id);
      // The stream may already have delivered the server copy.
      final duplicate = _messages.indexWhere((m) => m.id == sent.id);
      if (i != -1) {
        if (duplicate != -1 && duplicate != i) {
          _messages.removeAt(i);
        } else {
          _messages[i] = sent;
        }
      }
    } on Object catch (e) {
      ErrorHandler.log(e);
      final i = _messages.indexWhere((m) => m.id == local.id);
      if (i != -1) _messages[i] = local.copyWith(status: MessageStatus.failed);
    }
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Live questions
  // ---------------------------------------------------------------------------

  /// Student: submit an answer. Returns an error message on failure.
  Future<String?> submitAnswer(String optionId) async {
    final q = _activeQuestion;
    if (q == null) return 'There is no active question.';
    _isSubmittingAnswer = true;
    _notify();
    try {
      _myResponse = await _questions.submitResponse(
        questionId: q.id,
        studentId: user.id,
        optionId: optionId,
      );
      return null;
    } on Object catch (e) {
      return ErrorHandler.message(e);
    } finally {
      _isSubmittingAnswer = false;
      _notify();
    }
  }

  /// Lecturer: launch a question to all participants.
  Future<QuestionModel> launchQuestion(QuestionModel draft) async {
    final launched = await _questions.launchQuestion(draft);
    _activeQuestion = launched;
    _lastQuestion = launched;
    _notify();
    return launched;
  }

  Future<QuestionModel> saveQuestionDraft(QuestionModel draft) =>
      _questions.saveDraft(draft);

  Future<void> closeQuestion() async {
    final q = _activeQuestion;
    if (q == null) return;
    _lastQuestion = await _questions.closeQuestion(q.id);
    _activeQuestion = null;
    _notify();
  }

  Future<void> broadcastResults() async {
    final q = lastQuestion;
    if (q == null) return;
    _lastQuestion = await _questions.broadcastResults(q.id);
    _activeQuestion = null;
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Attendance (lecturer)
  // ---------------------------------------------------------------------------

  Future<void> startAttendance() async {
    _session = await _attendance.startAttendance(sessionId);
    _notify();
  }

  Future<void> endAttendance() async {
    _session = await _attendance.endAttendance(sessionId);
    _sessionAttendance = await _attendance.getSessionAttendance(sessionId);
    _notify();
  }

  Future<void> markAttendance(String studentId, AttendanceStatus status) async {
    await _attendance.markAttendance(
      sessionId: sessionId,
      studentId: studentId,
      status: status,
    );
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  Future<void> leave() async {
    if (!_joined) return;
    _joined = false;
    await _safe(() => _classroom.leaveClass(sessionId, user.id));
    await _safe(_media.leaveRoom);
    await _safe(_socket.disconnect);
    _notify();
  }

  /// Lecturer: end the class for everyone.
  Future<void> endClass() async {
    _isEnding = true;
    _notify();
    try {
      if (attendanceActive) await _attendance.endAttendance(sessionId);
      _session = await _classroom.endClass(sessionId);
    } finally {
      _isEnding = false;
      await leave();
    }
  }

  Future<void> _safe(Future<void> Function() action) async {
    try {
      await action();
    } on Object catch (e) {
      ErrorHandler.log(e);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final s in _subscriptions) {
      s.cancel();
    }
    if (_joined) {
      _joined = false;
      _classroom.leaveClass(sessionId, user.id).catchError(ErrorHandler.log);
      _media.leaveRoom().catchError(ErrorHandler.log);
      _socket.disconnect().catchError(ErrorHandler.log);
    }
    super.dispose();
  }
}
