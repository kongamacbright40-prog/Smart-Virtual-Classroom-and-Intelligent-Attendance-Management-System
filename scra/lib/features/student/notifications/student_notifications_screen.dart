import 'package:flutter/material.dart';

import '../../../../widgets/common/app_bar.dart';
import '../../../../widgets/common/empty_state.dart';

// TODO(phase): replace placeholder with the Stitch design implementation.
class StudentNotificationsScreen extends StatelessWidget {
  const StudentNotificationsScreen({super.key,});


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: SmartAppBar(title: 'Notifications'),
      body: EmptyState(
        icon: Icons.construction_outlined,
        title: 'Notifications',
        message: 'This screen is being implemented.',
      ),
    );
  }
}
