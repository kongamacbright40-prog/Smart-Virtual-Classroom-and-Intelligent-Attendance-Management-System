import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_handler.dart';
import '../buttons/primary_button.dart';

/// Error placeholder with a retry action. Accepts either an [error] object
/// (normalized through [ErrorHandler]) or a plain [message].
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.error,
    this.message,
    this.title,
    this.onRetry,
    this.retryLabel = AppStrings.retry,
    this.compact = false,
  });

  final Object? error;
  final String? message;
  final String? title;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = error == null ? null : ErrorHandler.normalize(error!);
    final isNetwork =
        normalized is NetworkException || normalized is TimeoutAppException;
    final text =
        message ?? normalized?.message ?? AppStrings.somethingWentWrong;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          compact ? AppDimensions.spaceMd : AppDimensions.spaceXl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spaceMd),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNetwork ? Icons.wifi_off_rounded : Icons.error_outline,
                size: compact ? 28 : 36,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceMd),
            Text(
              title ??
                  (isNetwork
                      ? 'Connection problem'
                      : AppStrings.somethingWentWrong),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppDimensions.spaceXs),
            Text(
              text,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppDimensions.spaceMd),
              PrimaryButton(
                label: retryLabel,
                icon: retryLabel == AppStrings.retry ? Icons.refresh : null,
                expanded: false,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
