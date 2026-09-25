import 'package:flutter/material.dart';

/// One bottom-navigation destination of a role shell.
class ShellDestination {
  const ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
}

/// Bottom-navigation shell shared by the Student, Lecturer and Admin apps.
/// Tabs are built lazily and kept alive in an [IndexedStack]; detail screens
/// are pushed on the root navigator.
class RoleShell extends StatefulWidget {
  const RoleShell({
    super.key,
    required this.destinations,
    this.initialIndex = 0,
    this.drawer,
  });

  final List<ShellDestination> destinations;
  final int initialIndex;
  final Widget? drawer;

  @override
  State<RoleShell> createState() => RoleShellState();
}

class RoleShellState extends State<RoleShell> {
  late int _index = widget.initialIndex.clamp(
    0,
    widget.destinations.length - 1,
  );
  late final List<Widget?> _pages = List<Widget?>.filled(
    widget.destinations.length,
    null,
  );

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int get index => _index;

  void openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void selectTab(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    _pages[_index] ??= widget.destinations[_index].builder(context);
    return ShellScope(
      state: this,
      index: _index,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: widget.drawer,
        body: IndexedStack(
          index: _index,
          children: [
            for (final page in _pages) page ?? const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: selectTab,
          destinations: [
            for (final d in widget.destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      ),
    );
  }
}

/// Gives descendants access to the enclosing shell, e.g. to switch tabs:
/// `ShellScope.maybeOf(context)?.selectTab(StudentTabs.schedule)`.
class ShellScope extends InheritedWidget {
  const ShellScope({
    super.key,
    required this.state,
    required this.index,
    required super.child,
  });

  final RoleShellState state;
  final int index;

  static RoleShellState? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>()?.state;

  /// Opens the drawer of the enclosing shell scaffold, if any.
  static void openDrawer(BuildContext context) {
    context.getInheritedWidgetOfExactType<ShellScope>()?.state.openDrawer();
  }

  @override
  bool updateShouldNotify(ShellScope oldWidget) => oldWidget.index != index;
}
