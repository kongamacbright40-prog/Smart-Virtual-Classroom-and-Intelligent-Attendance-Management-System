import '../../core/errors/app_exception.dart';
import '../../models/models.dart';
import '../repositories.dart';
import 'mock_data_store.dart';
import 'mock_repository_base.dart';

class MockClassroomRepository extends MockRepositoryBase
    implements ClassroomRepository {
  MockClassroomRepository(this._store, {super.latency});

  final MockDataStore _store;

  List<ParticipantModel> _list(String sessionId) =>
      _store.participants.putIfAbsent(sessionId, () => []);

  void _emit(String sessionId) => _store
      .participantChannel(sessionId)
      .add(List.unmodifiable(_list(sessionId)));

  ClassSessionModel _setStatus(String sessionId, SessionStatus status) {
    final s = _store.sessions[sessionId];
    if (s == null) throw const NotFoundException('Class session not found.');
    final updated = s.copyWith(
      status: status,
      attendanceActive: status == SessionStatus.live,
      startTime: status == SessionStatus.live && s.startTime.isAfter(DateTime.now())
          ? DateTime.now()
          : null,
      endTime: status == SessionStatus.completed ? DateTime.now() : null,
    );
    _store.sessions[sessionId] = updated;
    return updated;
  }

  @override
  Future<ClassSessionModel> startClass(String sessionId) =>
      delay(() => _setStatus(sessionId, SessionStatus.live));

  @override
  Future<ClassSessionModel> endClass(String sessionId) => delay(() {
        final updated = _setStatus(sessionId, SessionStatus.completed);
        _store.participants[sessionId] = [];
        _emit(sessionId);
        return updated;
      });

  @override
  Future<void> joinClass(String sessionId, UserModel user) => delay(() {
        final session = _store.sessions[sessionId];
        if (session == null) {
          throw const NotFoundException('Class session not found.');
        }
        if (session.status != SessionStatus.live &&
            user.role != UserRole.lecturer) {
          throw const ValidationException('This class is not live yet.');
        }
        final list = _list(sessionId);
        list.removeWhere((p) => p.userId == user.id);
        list.add(ParticipantModel(
          userId: user.id,
          name: user.fullName,
          role: user.role,
          joinedAt: DateTime.now(),
          isMuted: true,
          isVideoOn: user.role == UserRole.lecturer,
        ));
        _store.sessions[sessionId] =
            session.copyWith(participantCount: list.length);
        _emit(sessionId);
      });

  @override
  Future<void> leaveClass(String sessionId, String userId) => delay(() {
        _list(sessionId).removeWhere((p) => p.userId == userId);
        _emit(sessionId);
      });

  void _update(String sessionId, String userId,
      ParticipantModel Function(ParticipantModel) change) {
    final list = _list(sessionId);
    final i = list.indexWhere((p) => p.userId == userId);
    if (i == -1) return;
    list[i] = change(list[i]);
    _emit(sessionId);
  }

  @override
  Future<void> setHandRaised(String sessionId, String userId, bool raised) =>
      delay(() => _update(
          sessionId, userId, (p) => p.copyWith(isHandRaised: raised)));

  @override
  Future<void> updateMediaState(
    String sessionId,
    String userId, {
    bool? isMuted,
    bool? isVideoOn,
    bool? isScreenSharing,
  }) =>
      delay(() => _update(
            sessionId,
            userId,
            (p) => p.copyWith(
              isMuted: isMuted,
              isVideoOn: isVideoOn,
              isScreenSharing: isScreenSharing,
            ),
          ));

  @override
  Stream<List<ParticipantModel>> watchParticipants(String sessionId) async* {
    yield List.unmodifiable(_list(sessionId));
    yield* _store.participantChannel(sessionId).stream;
  }

  @override
  Future<List<ChatMessageModel>> getMessages(String sessionId) =>
      delay(() => List.of(_store.messages[sessionId] ?? const []));

  @override
  Stream<ChatMessageModel> watchMessages(String sessionId) =>
      _store.chatChannel(sessionId).stream;

  @override
  Future<ChatMessageModel> sendMessage(ChatMessageModel message) => delay(() {
        if (message.message.trim().isEmpty) {
          throw const ValidationException('Message cannot be empty.');
        }
        final sent = message.copyWith(
          id: message.id.startsWith('local-')
              ? _store.nextId('msg')
              : message.id,
          status: MessageStatus.sent,
        );
        _store.messages.putIfAbsent(message.classroomId, () => []).add(sent);
        _store.chatChannel(message.classroomId).add(sent);
        return sent;
      });
}
