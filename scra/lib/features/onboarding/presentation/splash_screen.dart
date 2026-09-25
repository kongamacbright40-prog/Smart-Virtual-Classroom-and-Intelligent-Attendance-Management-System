import 'package:flutter/material.dart';

import '../../../widgets/common/empty_state.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: EmptyState(title: 'SplashScreen'));
}
