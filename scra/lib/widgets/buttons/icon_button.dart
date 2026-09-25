import 'package:flutter/material.dart';

/// Circular icon button with a tonal background (header search/bell,
/// classroom controls).
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 44,
    this.backgroundColor,
    this.foregroundColor,
    this.badge = false,
    this.badgeCount,
    this.active = false,
    this.activeColor,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  /// Shows a red dot (e.g. unread notifications).
  final bool badge;
  final int? badgeCount;
  final bool active;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = active
        ? (activeColor ?? scheme.primaryContainer)
        : (backgroundColor ?? scheme.surfaceContainerHigh);
    final fg = active ? scheme.onPrimary : (foregroundColor ?? scheme.onSurface);

    Widget button = Material(
      color: bg,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox.square(
          dimension: size,
          child: Icon(icon, color: fg, size: size * 0.5),
        ),
      ),
    );

    if (badge || (badgeCount ?? 0) > 0) {
      button = Badge(
        isLabelVisible: true,
        backgroundColor: scheme.error,
        label: badgeCount != null && badgeCount! > 0
            ? Text(badgeCount! > 99 ? '99+' : '$badgeCount')
            : null,
        smallSize: 10,
        offset: const Offset(-4, 4),
        child: button,
      );
    }

    return Semantics(
      button: true,
      label: tooltip,
      child: tooltip == null ? button : Tooltip(message: tooltip!, child: button),
    );
  }
}
