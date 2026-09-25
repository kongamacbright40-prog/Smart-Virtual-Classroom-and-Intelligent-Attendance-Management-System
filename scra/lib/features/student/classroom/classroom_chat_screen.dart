import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/models.dart';
import '../../../providers/classroom_controller.dart';
import '../../../providers/classroom_registry.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/error_state.dart';
import '../../../widgets/common/loading_state.dart';
import 'widgets/chat_message.dart';

class ClassroomChatScreen extends StatefulWidget {
  const ClassroomChatScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<ClassroomChatScreen> createState() => _ClassroomChatScreenState();
}

class _ClassroomChatScreenState extends State<ClassroomChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _asQuestion = false;
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClassroomScope(
      sessionId: widget.sessionId,
      child: Consumer<ClassroomController>(
        builder: (context, controller, _) {
          if (controller.isLoading) return const Scaffold(body: LoadingState());
          if (controller.errorMessage != null) {
            return Scaffold(
              body: ErrorState(
                message: controller.errorMessage,
                onRetry: () => controller.init(),
              ),
            );
          }
          final messages = [...controller.messages]
            ..sort((a, b) {
              if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
              return a.timestamp.compareTo(b.timestamp);
            });
          final session = controller.session;
          return AppScaffold(
            padding: EdgeInsets.zero,
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: Column(
              children: [
                _ChatHeader(
                  controller: controller,
                  title: session?.courseCode ?? 'Classroom',
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppDimensions.spaceMd),
                    itemCount: messages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Center(
                          child: Chip(
                            label: Text(
                              'Today • ${Formatters.time(DateTime.now())}',
                            ),
                          ),
                        );
                      }
                      final message = messages[index - 1];
                      return ChatMessageBubble(
                        message: message,
                        isOwn: message.senderId == controller.user.id,
                        onRetry: message.status == MessageStatus.failed
                            ? () => controller.retryMessage(message)
                            : null,
                      );
                    },
                  ),
                ),
                _Composer(
                  controller: _controller,
                  asQuestion: _asQuestion,
                  isSending: _sending,
                  onQuestionChanged: (value) =>
                      setState(() => _asQuestion = value),
                  onSend: () => _send(controller),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _send(ClassroomController classroom) async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      await classroom.sendMessage(text, isQuestion: _asQuestion);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.controller, required this.title});

  final ClassroomController controller;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spaceMd),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(AppDimensions.radiusXl),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Classroom Chat',
                        style: theme.textTheme.headlineSmall,
                      ),
                      Text(
                        '$title: ${controller.session?.courseTitle ?? 'Live Class'} • ${controller.participantCount} active',
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.keyboard_arrow_down),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Public Chat'),
                    icon: Icon(Icons.forum_outlined),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Q&A'),
                    icon: Icon(Icons.quiz_outlined),
                  ),
                ],
                selected: const {false},
                onSelectionChanged: (_) {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.asQuestion,
    required this.isSending,
    required this.onQuestionChanged,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool asQuestion;
  final bool isSending;
  final ValueChanged<bool> onQuestionChanged;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text('Ask as question'),
                value: asQuestion,
                onChanged: onQuestionChanged,
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.attach_file),
                  ),
                  Expanded(
                    child: TextField(
                      key: const Key('chat_input'),
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                      decoration: InputDecoration(
                        hintText: 'Send a message...',
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusFull,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceSm),
                  IconButton.filled(
                    key: const Key('chat_send'),
                    onPressed: isSending ? null : onSend,
                    icon: isSending
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
