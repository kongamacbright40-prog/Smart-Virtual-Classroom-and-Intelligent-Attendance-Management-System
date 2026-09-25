import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/helpers.dart';
import '../../../models/models.dart';
import '../../../providers/classroom_controller.dart';
import '../../../providers/classroom_registry.dart';
import '../../../widgets/buttons/secondary_button.dart';
import '../../../widgets/common/app_bar.dart';
import '../../../widgets/common/app_card.dart';
import '../../../widgets/common/status_chip.dart';
import '../lecturer_shared.dart';
import 'widgets/question_form.dart';

class CreateQuestionScreen extends StatelessWidget {
  const CreateQuestionScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return ClassroomScope(
      sessionId: sessionId,
      child: _CreateQuestionBody(sessionId: sessionId),
    );
  }
}

class _CreateQuestionBody extends StatelessWidget {
  const _CreateQuestionBody({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ClassroomController>();
    return Scaffold(
      appBar: const SmartAppBar(title: 'Launch Quick Question'),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.pageMargin),
        children: [
          Wrap(
            spacing: AppDimensions.spaceSm,
            children: [
              if (controller.session != null)
                CodeTag(controller.session!.courseCode),
              const Text('• Question'),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          QuestionForm(
            sessionId: sessionId,
            onLaunch: (question) async {
              try {
                await controller.launchQuestion(question);
                if (context.mounted) {
                  Helpers.showSnackBar(context, 'Question launched.');
                }
              } on Object catch (e) {
                if (context.mounted) Helpers.showError(context, e);
              }
            },
            onSaveDraft: (question) async {
              try {
                await controller.saveQuestionDraft(question);
                if (context.mounted) {
                  Helpers.showSnackBar(context, 'Draft saved.');
                }
              } on Object catch (e) {
                if (context.mounted) Helpers.showError(context, e);
              }
            },
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          if (controller.lastQuestion != null)
            _BroadcastPanel(
              question: controller.lastQuestion!,
              controller: controller,
            ),
        ],
      ),
    );
  }
}

class _BroadcastPanel extends StatelessWidget {
  const _BroadcastPanel({required this.question, required this.controller});

  final QuestionModel question;
  final ClassroomController controller;

  @override
  Widget build(BuildContext context) {
    final remaining = question.remainingAt(DateTime.now());
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.circle, size: 12, color: Colors.green),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(
                child: Text(
                  'Live Broadcast Active',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (remaining != null)
                Chip(
                  label: Text('${Formatters.countdown(remaining)} remaining'),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Row(
            children: [
              const Expanded(child: Text('Students Responding')),
              Text(
                '${question.responseCount} / ${question.expectedResponders} (${attendancePercent(question.responseRate)})',
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          LinearProgressIndicator(value: question.responseRate / 100),
          const SizedBox(height: AppDimensions.spaceMd),
          Text(
            'Live Distribution',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          for (final option in question.options)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
              child: Row(
                children: [
                  SizedBox(width: 34, child: Text('${option.label}:')),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: question.percentFor(option.id) / 100,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceSm),
                  SizedBox(
                    width: 76,
                    child: Text(
                      '${option.responseCount}${option.id == question.correctOptionId ? ' ★' : ''}  ${attendancePercent(question.percentFor(option.id))}',
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppDimensions.spaceMd),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'End Early',
                  icon: Icons.stop_circle_outlined,
                  foregroundColor: Theme.of(context).colorScheme.error,
                  onPressed: () async {
                    await controller.closeQuestion();
                    if (context.mounted) {
                      Helpers.showSnackBar(context, 'Question ended.');
                    }
                  },
                ),
              ),
              const SizedBox(width: AppDimensions.spaceSm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    await controller.broadcastResults();
                    if (context.mounted) {
                      Helpers.showSnackBar(context, 'Results broadcast.');
                    }
                  },
                  icon: const Icon(Icons.leaderboard_outlined),
                  label: const Text('Broadcast Results'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
