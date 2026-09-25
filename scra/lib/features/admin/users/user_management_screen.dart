import 'package:flutter/material.dart';

import '../../../../widgets/common/app_bar.dart';
import '../../../../widgets/common/empty_state.dart';

// TODO(phase): replace placeholder with the Stitch design implementation.
class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key,});


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: SmartAppBar(title: 'User Management'),
      body: EmptyState(
        icon: Icons.construction_outlined,
        title: 'User Management',
        message: 'This screen is being implemented.',
      ),
    );
  }
}
