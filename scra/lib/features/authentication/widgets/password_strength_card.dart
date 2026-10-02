import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/validators.dart';
import '../../../widgets/common/progress_bar.dart';

/// Live password strength card with rule checklist (Stitch screens 07/08/10).
class PasswordStrengthCard extends StatelessWidget {
  const PasswordStrengthCard({
    super.key,
    required this.password,
    this.compact = false,
    this.extraNote,
  });

  final String password;

  /// Compact variant shows satisfied rules as chips (Forgot Password).
  final bool compact;

  /// Additional informational line (e.g. 2FA notice).
  final String? extraNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strength = Validators.passwordStrength(password);
    final rules = [
      (
        '${AppConstants.recommendedPasswordLength}+ characters',
        strength.hasMinLength,
      ),
      ('An uppercase letter (A–Z)', strength.hasUppercase),
      ('A number (0–9)', strength.hasDigit),
      (r'A special symbol (!@#$%^&*)', strength.hasSpecial),
    ];
    final color = switch (strength.score) {
      0 || 1 => AppColors.error,
      2 => AppColors.warning,
      _ => theme.colorScheme.secondary,
    };

    if (compact) {
      final chips = [
        (
          '${AppConstants.recommendedPasswordLength}+ characters',
          strength.hasMinLength,
        ),
        ('1 number', strength.hasDigit),
        ('1 special char', strength.hasSpecial),
      ];
      final met = chips.where((c) => c.$2).length;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'Security Strength: ',
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge,
                ),
              ),
              Flexible(
                child: Text(
                  password.isEmpty ? '—' : strength.label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(color: color),
                ),
              ),
              const Spacer(),
              Text(
                '$met / ${chips.length}',
                style: theme.textTheme.labelLarge?.copyWith(color: color),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          SegmentedProgress(total: chips.length, filled: met, color: color),
          const SizedBox(height: AppDimensions.spaceSm),
          Wrap(
            spacing: AppDimensions.spaceSm,
            runSpacing: AppDimensions.spaceSm,
            children: [
              for (final c in chips)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: c.$2
                        ? AppColors.secondaryFixed
                        : theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusFull,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        c.$2 ? Icons.check : Icons.remove,
                        size: 14,
                        color: c.$2
                            ? AppColors.onSecondaryFixedVariant
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(c.$1, style: theme.textTheme.labelMedium),
                    ],
                  ),
                ),
            ],
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Security Strength',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Flexible(
                child: Text(
                  password.isEmpty ? '—' : strength.label,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(color: color),
                ),
              ),
              const SizedBox(width: 6),
              Text('${strength.score}/4', style: theme.textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          SegmentedProgress(total: 4, filled: strength.score, color: color),
          const SizedBox(height: AppDimensions.spaceSm),
          Text(
            'Only ${AppConstants.minPasswordLength} characters are required. '
            'These make your password stronger:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceSm),
          for (final r in rules)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: r.$2
                          ? AppColors.secondaryFixed
                          : theme.colorScheme.surfaceContainerHigh,
                    ),
                    child: Icon(
                      r.$2 ? Icons.check : Icons.radio_button_unchecked,
                      size: 14,
                      color: r.$2
                          ? AppColors.onSecondaryFixedVariant
                          : theme.colorScheme.outline,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.spaceSm),
                  Expanded(
                    child: Text(
                      r.$1,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: r.$2 ? null : theme.colorScheme.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (extraNote != null)
            Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppDimensions.spaceSm),
                Expanded(
                  child: Text(extraNote!, style: theme.textTheme.bodySmall),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
