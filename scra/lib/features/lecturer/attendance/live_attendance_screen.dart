import 'package:flutter/material.dart';

import '../../../../widgets/common/app_bar.dart';
import '../../../../widgets/common/empty_state.dart';

// TODO(phase): replace placeholder with the Stitch design implementation.
class LiveAttendanceScreen extends StatelessWidget {
  const LiveAttendanceScreen({super.key, this.sessionId,});

  final String? sessionId;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: SmartAppBar(title: 'Live Attendance'),
      body: EmptyState(
        icon: Icons.construction_outlined,
        title: 'Live Attendance',
        message: 'This screen is being implemented.',
      ),
    );
  }
}
