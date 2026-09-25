import 'package:flutter/material.dart';

import '../../../../widgets/common/app_bar.dart';
import '../../../../widgets/common/empty_state.dart';

// TODO(phase): replace placeholder with the Stitch design implementation.
class StudentAttendanceScreen extends StatelessWidget {
  const StudentAttendanceScreen({super.key,});


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: SmartAppBar(title: 'My Attendance'),
      body: EmptyState(
        icon: Icons.construction_outlined,
        title: 'My Attendance',
        message: 'This screen is being implemented.',
      ),
    );
  }
}
