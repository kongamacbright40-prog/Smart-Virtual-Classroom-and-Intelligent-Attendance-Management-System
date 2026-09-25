import 'package:flutter/material.dart';

import '../../../../widgets/common/app_bar.dart';
import '../../../../widgets/common/empty_state.dart';

// TODO(phase): replace placeholder with the Stitch design implementation.
class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key,});


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: SmartAppBar(title: 'Student Home'),
      body: EmptyState(
        icon: Icons.construction_outlined,
        title: 'Student Home',
        message: 'This screen is being implemented.',
      ),
    );
  }
}
