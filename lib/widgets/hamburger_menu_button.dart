import 'package:flutter/material.dart';
import '../core/inherited/shell_scaffold.dart';

/// Opens the enclosing shell's drawer. Renders nothing when there's no
/// [ShellScaffold] above it in the tree — e.g. Admin's desktop layout, which
/// uses a permanent sidebar instead of a drawer — so screens shared between
/// layouts can use this unconditionally without checking screen size themselves.
class HamburgerMenuButton extends StatelessWidget {
  final Color? color;
  const HamburgerMenuButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final shell = ShellScaffold.of(context);
    if (shell == null) return const SizedBox.shrink();
    return IconButton(
      icon: Icon(Icons.menu, color: color),
      tooltip: 'Menu',
      onPressed: () => shell.scaffoldKey.currentState?.openDrawer(),
    );
  }
}
