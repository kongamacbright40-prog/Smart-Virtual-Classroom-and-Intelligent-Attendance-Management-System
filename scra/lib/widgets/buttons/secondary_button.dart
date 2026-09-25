import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';

enum SecondaryButtonStyle { tonal, outlined, text }

/// Grey tonal / outlined button (`← Back`, `Save Draft`, `University SSO`).
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.style = SecondaryButtonStyle.tonal,
    this.expanded = true,
    this.foregroundColor,
    this.backgroundColor,
    this.isLoading = false,
    this.height = AppDimensions.buttonHeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final IconData? trailingIcon;
  final SecondaryButtonStyle style;
  final bool expanded;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final bool isLoading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = foregroundColor ?? scheme.onSurface;
    final content = isLoading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
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
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: AppDimensions.spaceSm),
                Icon(trailingIcon, size: 20),
              ],
            ],
          );
    final size = Size(expanded ? double.infinity : 64, height);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
    );
    final padding = const EdgeInsets.symmetric(
      horizontal: AppDimensions.spaceMd,
    );
    final onTap = isLoading ? null : onPressed;

    return switch (style) {
      SecondaryButtonStyle.tonal => FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor ?? scheme.surfaceContainerHigh,
          foregroundColor: fg,
          minimumSize: size,
          shape: shape,
          padding: padding,
        ),
        child: content,
      ),
      SecondaryButtonStyle.outlined => OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor ?? scheme.surfaceContainerLowest,
          foregroundColor: fg,
          minimumSize: size,
          shape: shape,
          padding: padding,
        ),
        child: content,
      ),
      SecondaryButtonStyle.text => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: foregroundColor ?? scheme.primary,
          minimumSize: size,
          shape: shape,
          padding: padding,
        ),
        child: content,
      ),
    };
  }
}
