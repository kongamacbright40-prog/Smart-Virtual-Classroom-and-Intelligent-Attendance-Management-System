import 'package:flutter/material.dart';

import '../../../../widgets/common/app_bar.dart';
import '../../../../widgets/common/empty_state.dart';

// TODO(phase): replace placeholder with the Stitch design implementation.
class WhiteboardScreen extends StatelessWidget {
  const WhiteboardScreen({super.key, required this.sessionId,});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: SmartAppBar(title: 'Whiteboard'),
      body: EmptyState(
        icon: Icons.construction_outlined,
        title: 'Whiteboard',
        message: 'This screen is being implemented.',
      ),
    );
  }
}
