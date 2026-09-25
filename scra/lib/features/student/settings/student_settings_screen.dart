import 'package:flutter/material.dart';

import '../../../../widgets/common/app_bar.dart';
import '../../../../widgets/common/empty_state.dart';

// TODO(phase): replace placeholder with the Stitch design implementation.
class StudentSettingsScreen extends StatelessWidget {
  const StudentSettingsScreen({super.key,});


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: SmartAppBar(title: 'Settings'),
      body: EmptyState(
        icon: Icons.construction_outlined,
        title: 'Settings',
        message: 'This screen is being implemented.',
      ),
    );
  }
}
