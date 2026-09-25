import 'package:flutter/material.dart';

import '../../../../widgets/common/app_bar.dart';
import '../../../../widgets/common/empty_state.dart';

// TODO(phase): replace placeholder with the Stitch design implementation.
class LecturerDashboardScreen extends StatelessWidget {
  const LecturerDashboardScreen({super.key,});


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: SmartAppBar(title: 'Lecturer Dashboard'),
      body: EmptyState(
        icon: Icons.construction_outlined,
        title: 'Lecturer Dashboard',
        message: 'This screen is being implemented.',
      ),
    );
  }
}
