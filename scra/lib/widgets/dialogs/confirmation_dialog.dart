import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';

/// Yes/No confirmation. Returns `true` when confirmed.
abstract final class ConfirmationDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = AppStrings.confirm,
    String cancelLabel = AppStrings.cancel,
    bool destructive = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          icon: icon == null
              ? null
              : Icon(icon, color: destructive ? scheme.error : scheme.primary),
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size(88, 44),
                backgroundColor: destructive ? scheme.error : null,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
