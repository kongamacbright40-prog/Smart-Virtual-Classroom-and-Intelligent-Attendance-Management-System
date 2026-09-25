import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_strings.dart';
import '../../core/routing/app_router.dart';
import '../../features/authentication/providers/auth_provider.dart';
import 'confirmation_dialog.dart';

/// Asks for confirmation, returns to [loginRoute] and clears the session.
///
/// Navigation happens first so the user never sees a role screen after the
/// session is gone; the session is then cleared in the background.
Future<void> confirmAndLogout(
  BuildContext context, {
  required String loginRoute,
}) async {
  final auth = context.read<AuthProvider>();
  final navigator = AppRouter.navigatorKey.currentState ?? Navigator.of(context);
  final ok = await ConfirmationDialog.show(
    context,
    title: AppStrings.logoutTitle,
    message: AppStrings.logoutMessage,
    confirmLabel: AppStrings.logout,
    destructive: true,
    icon: Icons.logout,
  );
  if (!ok) return;
  navigator.pushNamedAndRemoveUntil(loginRoute, (_) => false);
  unawaited(auth.logout());
}
