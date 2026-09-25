import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../models/models.dart';
import '../../../../widgets/buttons/primary_button.dart';
import '../../../../widgets/common/app_card.dart';
import '../../../../widgets/inputs/app_dropdown.dart';
import '../../../../widgets/inputs/app_text_field.dart';

class ClassForm extends StatefulWidget {
  const ClassForm({
    super.key,
    required this.courses,
    required this.initialCourseId,
    required this.onSubmit,
  });

  final List<CourseModel> courses;
  final String? initialCourseId;
  final Future<void> Function(ScheduleModel request) onSubmit;

  @override
  State<ClassForm> createState() => _ClassFormState();
}

class _ClassFormState extends State<ClassForm> {
  final _formKey = GlobalKey<FormState>();
  final _topic = TextEditingController();
  final _room = TextEditingController();
  CourseModel? _course;
  late DateTime _date;
  late TimeOfDay _time;
  int _duration = 90;
  int _lateThreshold = 10;
  bool _enableQuestions = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now().add(const Duration(days: 6));
    _time = const TimeOfDay(hour: 10, minute: 0);
    if (widget.courses.isNotEmpty) {
      _course = widget.initialCourseId == null
          ? widget.courses.first
          : widget.courses.firstWhere(
              (c) => c.id == widget.initialCourseId,
              orElse: () => widget.courses.first,
            );
      _room.text = _course?.room ?? '';
    }
  }

  @override
  void dispose() {
    _topic.dispose();
    _room.dispose();
    super.dispose();
  }

  DateTime get _start =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _course == null) return;
    setState(() => _submitting = true);
    final course = _course!;
    final request = ScheduleModel(
      id: '',
      courseId: course.id,
      courseCode: course.code,
      courseTitle: course.title,
      topic: _topic.text.trim(),
      startTime: _start,
      durationMinutes: _duration,
      lateThresholdMinutes: _lateThreshold,
      enableQuestions: _enableQuestions,
      room: _room.text.trim().isEmpty ? course.room : _room.text.trim(),
    );
    try {
      await widget.onSubmit(request);
    } finally {
      if (mounted) setState(() => _submitting = false);
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
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer
                      .withValues(alpha: 0.18),
                  child: Icon(Icons.sensors, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: AppDimensions.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Automated Session Setup',
                        style: theme.textTheme.titleMedium,
                      ),
                      const Text(
                        'Set up upcoming lecture or tutorial session. Automated attendance & geofencing activates at start time.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppDropdown<CourseModel>(
            label: 'Select Course',
            isRequired: true,
            items: widget.courses,
            value: _course,
            itemLabel: (course) => '${course.code} ? ${course.title}',
            prefixIcon: Icons.school_outlined,
            validator: (value) => value == null ? 'Course is required' : null,
            onChanged: (value) {
              setState(() {
                _course = value;
                _room.text = value?.room ?? '';
              });
            },
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppTextField(
            fieldKey: const Key('schedule_topic'),
            controller: _topic,
            label: 'Session Topic / Title',
            isRequired: true,
            hint: 'Binary Search Trees & Balancing (AVL)',
            prefixIcon: Icons.edit_note,
            maxLength: 60,
            helper: 'Visible to students on schedule and notification alerts',
            validator: (value) {
              final required = Validators.required(
                value,
                field: 'Session topic',
              );
              if (required != null) return required;
              if (value!.trim().length > 60) {
                return 'Topic must be 60 characters or less';
              }
              return null;
            },
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Date',
                  isRequired: true,
                  readOnly: true,
                  prefixIcon: Icons.calendar_today,
                  initialValue: Formatters.shortDate(_date),
                  onTap: _pickDate,
                  validator: (_) => Validators.classDate(_date),
                ),
              ),
              const SizedBox(width: AppDimensions.spaceMd),
              Expanded(
                child: AppTextField(
                  label: 'Start Time',
                  isRequired: true,
                  readOnly: true,
                  prefixIcon: Icons.schedule,
                  initialValue: _time.format(context),
                  onTap: _pickTime,
                  validator: (_) => null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppDropdown<int>(
            label: 'Duration',
            isRequired: true,
            items: const [45, 60, 75, 90, 120],
            value: _duration,
            itemLabel: (value) => '$value mins',
            prefixIcon: Icons.timer_outlined,
            onChanged: (value) => setState(() => _duration = value ?? 90),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          Text('Late Arrival Threshold', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppDimensions.spaceXs),
          Wrap(
            spacing: AppDimensions.spaceSm,
            children: [
              for (final value in [5, 10, 15, 20, 30])
                ChoiceChip(
                  label: Text('$value min'),
                  selected: _lateThreshold == value,
                  onSelected: (_) => setState(() => _lateThreshold = value),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable Participation Questions'),
            subtitle: const Text(
              'Allows in-class pop quizzes and micro-polls.',
            ),
            secondary: const Icon(Icons.quiz_outlined),
            value: _enableQuestions,
            onChanged: (value) => setState(() => _enableQuestions = value),
          ),
          const SizedBox(height: AppDimensions.spaceMd),
          AppTextField(
            controller: _room,
            label: 'Room',
            prefixIcon: Icons.meeting_room_outlined,
            hint: 'Hall B • Turing Wing',
          ),
          const SizedBox(height: AppDimensions.spaceLg),
          PrimaryButton(
            key: const Key('schedule_submit'),
            label: 'Schedule & Create Room',
            icon: Icons.calendar_month,
            isLoading: _submitting,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
