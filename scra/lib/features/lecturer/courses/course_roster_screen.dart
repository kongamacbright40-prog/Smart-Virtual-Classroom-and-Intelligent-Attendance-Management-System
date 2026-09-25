import 'package:flutter/material.dart';

import '../../../../widgets/common/app_bar.dart';
import '../../../../widgets/common/empty_state.dart';

// TODO(phase): replace placeholder with the Stitch design implementation.
class CourseRosterScreen extends StatelessWidget {
  const CourseRosterScreen({super.key, required this.courseId,});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: SmartAppBar(title: 'Course Roster'),
      body: EmptyState(
        icon: Icons.construction_outlined,
        title: 'Course Roster',
        message: 'This screen is being implemented.',
      ),
    );
  }
}
