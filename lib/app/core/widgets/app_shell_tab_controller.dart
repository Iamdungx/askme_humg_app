import 'package:flutter/material.dart';

/// Bottom [NavigationBar] indices for [AppShell] — must match `router.dart`
/// `StatefulShellRoute` branch order.
abstract final class AppShellTab {
  static const int feed = 0;
  static const int inbox = 1;
  static const int profile = 2;
  static const int settings = 3;
}

/// Exposes the same tab switch as tapping the bottom bar (fade + goBranch).
///
/// Used e.g. when opening “own profile” from feed so transition matches manual
/// tab taps instead of a hard `go('/me')`.
class AppShellTabController extends InheritedWidget {
  const AppShellTabController({
    super.key,
    required this.switchToTab,
    required super.child,
  });

  final void Function(int index) switchToTab;

  static AppShellTabController? maybeOf(BuildContext context) =>
      context.findAncestorWidgetOfExactType<AppShellTabController>();

  @override
  bool updateShouldNotify(AppShellTabController oldWidget) =>
      oldWidget.switchToTab != switchToTab;
}
