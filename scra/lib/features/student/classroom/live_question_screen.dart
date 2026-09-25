import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/models.dart';
import '../../../providers/classroom_controller.dart';
import '../../../providers/classroom_registry.dart';
import '../../../widgets/buttons/primary_button.dart';
import '../../../widgets/common/app_scaffold.dart';
import '../../../widgets/common/empty_state.dart';
import '../../../widgets/common/error_state.dart';
import '../../../widgets/common/loading_state.dart';
import '../../../widgets/common/status_chip.dart';

class LiveQuestionScreen extends StatefulWidget {
  const LiveQuestionScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<LiveQuestionScreen> createState() => _LiveQuestionScreenState();
}

class _LiveQuestionScreenState extends State<LiveQuestionScreen> {
  Timer? _timer;
  String? _selectedOptionId;
  String? _lastSubmittedOptionId;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
          final question = controller.activeQuestion;
          final response = controller.myResponse;
          if (question == null && response == null) {
            return const AppScaffold(
              body: EmptyState(
                icon: Icons.quiz_outlined,
                title: 'No active question',
                message: 'Your lecturer has not launched a live question yet.',
              ),
            );
          }
          final visibleQuestion = question ?? controller.lastQuestion;
          if (visibleQuestion == null) {
            return const AppScaffold(
              body: EmptyState(title: 'No active question'),
            );
          }
          return AppScaffold(
            scrollable: true,
            padding: const EdgeInsets.all(AppDimensions.spaceLg),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _QuestionHeader(question: visibleQuestion),
                const SizedBox(height: AppDimensions.spaceXl),
                _QuestionText(question: visibleQuestion),
                const SizedBox(height: AppDimensions.spaceLg),
                for (final option in visibleQuestion.options) ...[
                  _OptionTile(
                    option: option,
                    selected:
                        (_selectedOptionId ?? response?.selectedOptionId) ==
                        option.id,
                    enabled: response == null && question != null,
                    onTap: () => setState(() => _selectedOptionId = option.id),
                  ),
                  const SizedBox(height: AppDimensions.spaceMd),
                ],
                if (response == null && question != null)
                  PrimaryButton(
                    key: const Key('submit_answer'),
                    label: 'Submit Answer',
                    icon: Icons.how_to_reg,
                    isLoading: controller.isSubmittingAnswer,
                    onPressed: _selectedOptionId == null
                        ? null
                        : () =>
                              _submit(context, controller, _selectedOptionId!),
                  )
                else
                  _SyncedState(
                    question: visibleQuestion,
                    response: response,
                    submittedOptionId: _lastSubmittedOptionId,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    ClassroomController controller,
    String optionId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final error = await controller.submitAnswer(optionId);
    if (error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _lastSubmittedOptionId = optionId);
  }
}

class _QuestionHeader extends StatelessWidget {
  const _QuestionHeader({required this.question});

  final QuestionModel question;

  @override
  Widget build(BuildContext context) {
    final remaining = question.remainingAt(DateTime.now());
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceMd),
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(Icons.bolt, color: theme.colorScheme.primary, size: 32),
          ),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Participation Check',
                  style: theme.textTheme.headlineSmall,
                ),
                Text(
                  'Live Lecture Poll • Points toward course grade',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (remaining != null)
            StatusChip(
              label: Formatters.countdown(remaining),
              tone: StatusTone.primary,
              icon: Icons.timelapse,
            ),
        ],
      ),
    );
  }
}

class _QuestionText extends StatelessWidget {
  const _QuestionText({required this.question});

  final QuestionModel question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceLg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppDimensions.spaceSm,
            children: [
              Chip(label: Text(question.topic ?? 'Single Choice')),
              const Chip(label: Text('Question 1 of 1')),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Text(question.text, style: theme.textTheme.headlineSmall),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final QuestionOption option;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? AppColors.primaryFixedDim
          : theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      child: InkWell(
        key: Key('question_option_${option.label}'),
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceLg),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    width: 2,
                  ),
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHigh,
                ),
                child: selected
                    ? Icon(
                        Icons.circle,
                        size: 10,
                        color: theme.colorScheme.onPrimary,
                      )
                    : null,
              ),
              const SizedBox(width: AppDimensions.spaceMd),
              Expanded(
                child: Text(
                  '${option.label} — ${option.text}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: selected ? theme.colorScheme.primary : null,
                  ),
                ),
              ),
              if (selected) const Chip(label: Text('Selected')),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncedState extends StatelessWidget {
  const _SyncedState({
    required this.question,
    required this.response,
    required this.submittedOptionId,
  });

  final QuestionModel question;
  final QuestionResponseModel? response;
  final String? submittedOptionId;

  @override
  Widget build(BuildContext context) {
    final optionId = response?.selectedOptionId ?? submittedOptionId;
    final label = question.options
        .where((o) => o.id == optionId)
        .map((o) => o.label)
        .cast<String?>()
        .firstOrNull;
    final isCorrect = response?.isCorrect;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect == false ? Icons.cancel : Icons.check_circle,
            color: isCorrect == false ? AppColors.error : AppColors.success,
          ),
          const SizedBox(width: AppDimensions.spaceMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCorrect == null
                      ? 'Response Synced to Session'
                      : isCorrect
                      ? 'Correct response synced'
                      : 'Incorrect response synced',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('Selected answer: ${label ?? optionId ?? '—'}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
