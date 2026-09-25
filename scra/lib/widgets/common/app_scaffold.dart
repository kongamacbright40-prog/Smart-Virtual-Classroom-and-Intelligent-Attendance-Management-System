import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';

/// Standard page scaffold: SafeArea, centered max-width content, consistent
/// margins and optional pull-to-refresh / scrolling.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.bottomBar,
    this.floatingActionButton,
    this.drawer,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppDimensions.pageMargin,
    ),
    this.scrollable = false,
    this.onRefresh,
    this.safeAreaTop = true,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;

  /// Sticky footer above the navigation bar (e.g. a primary CTA).
  final Widget? bottomBar;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final bool scrollable;
  final Future<void> Function()? onRefresh;
  final bool safeAreaTop;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(padding: padding, child: body);
    if (scrollable) {
      content = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppDimensions.spaceLg),
        child: content,
      );
    }
    if (onRefresh != null) {
      content = RefreshIndicator(onRefresh: onRefresh!, child: content);
    }
    content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.maxContentWidth,
        ),
        child: content,
      ),
    );

    return Scaffold(
      appBar: appBar,
      drawer: drawer,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: SafeArea(
        top: safeAreaTop && appBar == null,
        bottom: bottomNavigationBar == null && bottomBar == null,
        child: bottomBar == null
            ? content
            : Column(
                children: [
                  Expanded(child: content),
                  SafeArea(
                    top: false,
                    bottom: bottomNavigationBar == null,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppDimensions.pageMargin,
                        AppDimensions.spaceSm,
                        AppDimensions.pageMargin,
                        AppDimensions.spaceMd,
                      ),
                      child: bottomBar,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
