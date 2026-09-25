import 'package:flutter/material.dart';

import '../../../../widgets/common/app_bar.dart';
import '../../../../widgets/common/empty_state.dart';

// TODO(phase): replace placeholder with the Stitch design implementation.
class CreateQuestionScreen extends StatelessWidget {
  const CreateQuestionScreen({super.key, required this.sessionId,});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: SmartAppBar(title: 'Create Live Question'),
      body: EmptyState(
        icon: Icons.construction_outlined,
        title: 'Create Live Question',
        message: 'This screen is being implemented.',
      ),
    );
  }
}
