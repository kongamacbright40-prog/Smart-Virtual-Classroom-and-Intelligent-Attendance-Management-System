import 'package:flutter/material.dart';

import '../../../../widgets/common/app_bar.dart';
import '../../../../widgets/common/empty_state.dart';

// TODO(phase): replace placeholder with the Stitch design implementation.
class CourseDetailsScreen extends StatelessWidget {
  const CourseDetailsScreen({super.key, required this.courseId,});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: SmartAppBar(title: 'Course Details'),
      body: EmptyState(
        icon: Icons.construction_outlined,
        title: 'Course Details',
        message: 'This screen is being implemented.',
      ),
    );
  }
}
