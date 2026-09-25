import 'package:flutter/material.dart';

import '../../../../widgets/common/app_bar.dart';
import '../../../../widgets/common/empty_state.dart';

// TODO(phase): replace placeholder with the Stitch design implementation.
class AcademicTermsScreen extends StatelessWidget {
  const AcademicTermsScreen({super.key,});


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: SmartAppBar(title: 'Academic Terms'),
      body: EmptyState(
        icon: Icons.construction_outlined,
        title: 'Academic Terms',
        message: 'This screen is being implemented.',
      ),
    );
  }
}
