import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';

/// Filled brand-blue button (`Sign In →`, `Join Live Session`...).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.expanded = true,
    this.backgroundColor,
    this.foregroundColor,
    this.height = AppDimensions.buttonHeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool expanded;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ?? Theme.of(context).colorScheme.onPrimary;
    final child = isLoading
        ? SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: fg),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: AppDimensions.spaceSm),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: AppDimensions.spaceSm),
                Icon(trailingIcon, size: 20),
              ],
            ],
          );

    final button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: fg,
        minimumSize: Size(expanded ? double.infinity : 64, height),
        disabledBackgroundColor: isLoading
            ? (backgroundColor ??
                      Theme.of(context).colorScheme.primaryContainer)
                  .withValues(alpha: 0.8)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceLg),
      ),
      child: child,
    );
    return Semantics(button: true, label: label, child: button);
  }
}
