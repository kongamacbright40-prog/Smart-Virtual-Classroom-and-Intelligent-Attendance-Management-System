import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../core/di/app_dependencies.dart';
import '../features/authentication/providers/auth_provider.dart';
import 'classroom_controller.dart';
import 'settings_provider.dart';

/// Keeps one [ClassroomController] per session alive while any screen
/// (classroom, chat, question, attendance...) is using it.
class ClassroomRegistry {
  ClassroomRegistry(this._deps);

  final AppDependencies _deps;
  final Map<String, ClassroomController> _controllers = {};
  final Map<String, int> _refs = {};

  ClassroomController? find(String sessionId) => _controllers[sessionId];

  ClassroomController acquire(
    String sessionId,
    AuthProvider auth,
    SettingsProvider settings,
  ) {
    _refs.update(sessionId, (v) => v + 1, ifAbsent: () => 1);
    final existing = _controllers[sessionId];
    if (existing != null) return existing;
    final user = auth.user;
    if (user == null) {
      throw StateError('A signed-in user is required to join a classroom.');
    }
    final controller = ClassroomController(
      sessionId: sessionId,
      user: user,
      classroomRepository: _deps.classroomRepository,
      questionRepository: _deps.questionRepository,
      attendanceRepository: _deps.attendanceRepository,
      scheduleRepository: _deps.scheduleRepository,
      webRTCService: _deps.webRTCService,
      webSocketService: _deps.webSocketService,
      joinWithMicOff: settings.settings.joinWithMicOff,
      joinWithCameraOff: settings.settings.joinWithCameraOff,
    );
    _controllers[sessionId] = controller;
    controller.init();
    return controller;
  }

  void release(String sessionId) {
    final count = (_refs[sessionId] ?? 1) - 1;
    if (count > 0) {
      _refs[sessionId] = count;
      return;
    }
    _refs.remove(sessionId);
    _controllers.remove(sessionId)?.dispose();
  }
}

/// Provides the shared [ClassroomController] for [sessionId] to [child].
///
/// Wrap every classroom-related screen with this widget; screens pushed from
/// the classroom (chat, live question...) automatically share its state.
class ClassroomScope extends StatefulWidget {
  const ClassroomScope({
    super.key,
    required this.sessionId,
    required this.child,
  });

  final String sessionId;
  final Widget child;

  @override
  State<ClassroomScope> createState() => _ClassroomScopeState();
}

class _ClassroomScopeState extends State<ClassroomScope> {
  late final ClassroomRegistry _registry;
  late final ClassroomController _controller;

  @override
  void initState() {
    super.initState();
    _registry = context.read<ClassroomRegistry>();
    _controller = _registry.acquire(
      widget.sessionId,
      context.read<AuthProvider>(),
      context.read<SettingsProvider>(),
    );
  }

  @override
  void dispose() {
    _registry.release(widget.sessionId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<ClassroomController>.value(
        value: _controller,
        child: widget.child,
      );
}
