import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/inherited/shell_scaffold.dart';
import '../widgets/vendor_drawer.dart';

class VendorShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const VendorShell({super.key, required this.navigationShell});

  @override
  State<VendorShell> createState() => _VendorShellState();
}

class _VendorShellState extends State<VendorShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      scaffoldKey: _scaffoldKey,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const VendorDrawer(),
        body: widget.navigationShell,
      ),
    );
  }
}
