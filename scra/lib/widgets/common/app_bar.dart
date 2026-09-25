import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import 'app_logo.dart';

/// Top app bar matching the Stitch headers: optional back button, a title
/// with an optional overline/subtitle, and trailing actions.
class SmartAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SmartAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.overline,
    this.actions,
    this.leading,
    this.showBack,
    this.centerTitle = false,
    this.showLogo = false,
    this.backgroundColor,
    this.foregroundColor,
    this.bottom,
    this.onBack,
  });

  final String? title;
  final String? subtitle;

  /// Small uppercase label above the title (e.g. `FACULTY GATEWAY`).
  final String? overline;
  final List<Widget>? actions;
  final Widget? leading;

  /// Defaults to `Navigator.canPop`.
  final bool? showBack;
  final bool centerTitle;
  final bool showLogo;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => Size.fromHeight(
        (subtitle != null || overline != null ? 68 : kToolbarHeight) +
            (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = showBack ?? Navigator.of(context).canPop();
    final fg = foregroundColor ?? theme.colorScheme.onSurface;

    Widget? leadingWidget = leading;
    if (leadingWidget == null && canPop) {
      leadingWidget = IconButton(
        tooltip: 'Back',
        icon: const Icon(Icons.arrow_back),
        onPressed: onBack ?? () => Navigator.of(context).maybePop(),
      );
    }

    final titleColumn = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        if (overline != null)
          Text(
            overline!.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 1.1,
            ),
          ),
        if (title != null)
          Text(
            title!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(color: fg),
          ),
        if (subtitle != null)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
      ],
    );

    return AppBar(
      backgroundColor: backgroundColor,
      foregroundColor: fg,
      automaticallyImplyLeading: false,
      leading: leadingWidget,
      centerTitle: centerTitle,
      titleSpacing: leadingWidget == null ? AppDimensions.pageMargin : 0,
      toolbarHeight: subtitle != null || overline != null ? 68 : kToolbarHeight,
      title: showLogo
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLogo(size: 36),
                const SizedBox(width: AppDimensions.spaceMd),
                Flexible(child: titleColumn),
              ],
            )
          : titleColumn,
      actions: [
        ...?actions,
        const SizedBox(width: AppDimensions.spaceXs),
      ],
      bottom: bottom,
    );
  }
}
