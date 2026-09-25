import 'package:flutter/material.dart';

import '../../../widgets/common/empty_state.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: EmptyState(title: 'WelcomeScreen'));
}
