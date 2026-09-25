import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/validators.dart';
import '../../../../models/models.dart';
import '../../../../widgets/buttons/primary_button.dart';
import '../../../../widgets/buttons/secondary_button.dart';
import '../../../../widgets/common/app_card.dart';
import '../../../../widgets/inputs/app_text_field.dart';

class QuestionForm extends StatefulWidget {
  const QuestionForm({
    super.key,
    required this.sessionId,
    required this.onLaunch,
    required this.onSaveDraft,
  });

  final String sessionId;
  final Future<void> Function(QuestionModel question) onLaunch;
  final Future<void> Function(QuestionModel question) onSaveDraft;

  @override
  State<QuestionForm> createState() => _QuestionFormState();
}

class _QuestionFormState extends State<QuestionForm> {
  final _formKey = GlobalKey<FormState>();
  final _prompt = TextEditingController();
  final List<TextEditingController> _options = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  int? _correct;
  int? _duration = 45;
  bool _busy = false;
  String? _optionsError;

  @override
  void dispose() {
    _prompt.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  QuestionModel _question() {
    final labels = ['A', 'B', 'C', 'D', 'E', 'F'];
    return QuestionModel(
      id: '',
      sessionId: widget.sessionId,
      text: _prompt.text.trim(),
      options: [
        for (var i = 0; i < _options.length; i++)
          QuestionOption(
            id: labels[i],
            label: labels[i],
            text: _options[i].text.trim(),
          ),
      ],
      correctOptionId: _correct == null ? null : labels[_correct!],
      durationSeconds: _duration,
    );
  }

  bool _validate() {
    final formOk = _formKey.currentState!.validate();
    final options = _options.map((c) => c.text).toList();
    final optionsError = Validators.questionOptions(options, _correct);
    setState(() => _optionsError = optionsError);
    return formOk && optionsError == null;
  }

  Future<void> _run(Future<void> Function(QuestionModel) action) async {
    if (!_validate()) return;
    setState(() => _busy = true);
    try {
      await action(_question());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            fieldKey: const Key('question_prompt'),
            controller: _prompt,
            label: 'Question Prompt',
            isRequired: true,
            maxLength: 150,
            maxLines: 4,
            hint: 'Enter a question for this class',
            validator: (value) {
              final base = Validators.questionText(value);
              if (base != null) return base;
              if (value!.trim().length > 150) {
                return 'Question must be under 150 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          Text('Response Options', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppDimensions.spaceSm),
          for (var i = 0; i < _options.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spaceSm),
              child: AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spaceSm,
                  vertical: AppDimensions.spaceXs,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      child: Text(String.fromCharCode(65 + i)),
                    ),
                    const SizedBox(width: AppDimensions.spaceSm),
                    Expanded(
                      child: TextFormField(
                        key: Key('question_option_$i'),
                        controller: _options[i],
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter option text',
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Set correct answer',
                      onPressed: () => setState(() => _correct = i),
                      icon: Icon(
                        _correct == i
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                      ),
                    ),
                    if (_options.length > AppConstants.minQuestionOptions)
                      IconButton(
                        tooltip: 'Remove option',
                        onPressed: () => setState(() {
                          final removed = _options.removeAt(i);
                          removed.dispose();
                          if (_correct != null &&
                              _correct! >= _options.length) {
                            _correct = _options.length - 1;
                          }
                        }),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                  ],
                ),
              ),
            ),
          if (_optionsError != null)
            Text(
              _optionsError!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
          if (_options.length < AppConstants.maxQuestionOptions)
            TextButton.icon(
              onPressed: () =>
                  setState(() => _options.add(TextEditingController())),
              icon: const Icon(Icons.add),
              label: const Text('Add Option'),
            ),
          const SizedBox(height: AppDimensions.spaceMd),
          Text('Question Timer', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppDimensions.spaceSm),
          Wrap(
            spacing: AppDimensions.spaceSm,
            children: [
              for (final option in [30, 45, 60, null])
                ChoiceChip(
                  label: Text(option == null ? 'Unlimited' : '$option sec'),
                  selected: _duration == option,
                  onSelected: (_) => setState(() => _duration = option),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          PrimaryButton(
            key: const Key('launch_question'),
            label: 'Launch Question',
            icon: Icons.send,
            isLoading: _busy,
            onPressed: () => _run(widget.onLaunch),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          SecondaryButton(
            label: 'Save Draft',
            icon: Icons.bookmark_border,
            isLoading: _busy,
            onPressed: () => _run(widget.onSaveDraft),
          ),
        ],
      ),
    );
  }
}
