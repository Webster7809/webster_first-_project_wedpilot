import 'package:flutter/material.dart';

/// Passes the outer shell's [ScaffoldState] key down the widget tree so that
/// screens nested inside inner Scaffolds can open the shell-level Drawer.
class ShellScaffold extends InheritedWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const ShellScaffold({
    super.key,
    required this.scaffoldKey,
    required super.child,
  });

  static ShellScaffold? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScaffold>();

  @override
  bool updateShouldNotify(ShellScaffold old) => scaffoldKey != old.scaffoldKey;
}
