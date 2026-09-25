import 'package:flutter/material.dart';

import '../../../../widgets/common/app_bar.dart';
import '../../../../widgets/common/empty_state.dart';

// TODO(phase): replace placeholder with the Stitch design implementation.
class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key,});


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: SmartAppBar(title: 'Student Profile'),
      body: EmptyState(
        icon: Icons.construction_outlined,
        title: 'Student Profile',
        message: 'This screen is being implemented.',
      ),
    );
  }
}
