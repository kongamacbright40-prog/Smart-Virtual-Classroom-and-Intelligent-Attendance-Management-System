import 'package:flutter/material.dart';

import '../../core/constants/app_strings.dart';
import '../../core/errors/error_handler.dart';

abstract final class ErrorDialog {
  static Future<void> show(
    BuildContext context, {
    Object? error,
    String? message,
    String title = AppStrings.somethingWentWrong,
    VoidCallback? onRetry,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return AlertDialog(
          icon: Icon(Icons.error_outline, color: scheme.error),
          title: Text(title),
          content: Text(
            message ??
                (error == null
                    ? AppStrings.somethingWentWrong
                    : ErrorHandler.message(error)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(AppStrings.close),
            ),
            if (onRetry != null)
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(88, 44)),
                onPressed: () {
                  Navigator.of(context).pop();
                  onRetry();
                },
                child: const Text(AppStrings.retry),
              ),
          ],
        );
      },
    );
  }
}
