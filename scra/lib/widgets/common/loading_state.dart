import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import '../loading/app_loader.dart';

/// Full-area loading placeholder, optionally with a message.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLoader(),
            if (message != null) ...[
              const SizedBox(height: AppDimensions.spaceMd),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
