import 'package:flutter/material.dart';

import '../../../../widgets/common/app_bar.dart';
import '../../../../widgets/common/empty_state.dart';

// TODO(phase): replace placeholder with the Stitch design implementation.
class StudentScheduleScreen extends StatelessWidget {
  const StudentScheduleScreen({super.key,});


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: SmartAppBar(title: 'Schedule'),
      body: EmptyState(
        icon: Icons.construction_outlined,
        title: 'Schedule',
        message: 'This screen is being implemented.',
      ),
    );
  }
}
