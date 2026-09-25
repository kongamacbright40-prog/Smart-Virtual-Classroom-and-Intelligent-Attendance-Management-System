import 'package:flutter/material.dart';

import '../../../models/user_model.dart';
import '../../../widgets/common/empty_state.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key, this.initialRole});

  final UserRole? initialRole;

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: EmptyState(title: 'LoginScreen'));
}
