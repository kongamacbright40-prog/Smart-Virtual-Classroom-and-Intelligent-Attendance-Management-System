import 'package:flutter/material.dart';

import '../../../../widgets/common/app_bar.dart';
import '../../../../widgets/common/empty_state.dart';

// TODO(phase): replace placeholder with the Stitch design implementation.
class FacultiesScreen extends StatelessWidget {
  const FacultiesScreen({super.key,});


  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: SmartAppBar(title: 'Faculties'),
      body: EmptyState(
        icon: Icons.construction_outlined,
        title: 'Faculties',
        message: 'This screen is being implemented.',
      ),
    );
  }
}
