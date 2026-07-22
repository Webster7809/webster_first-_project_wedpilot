import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/inherited/shell_scaffold.dart';
import '../widgets/app_drawer.dart';

class CoupleShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const CoupleShell({super.key, required this.navigationShell});

  @override
  State<CoupleShell> createState() => _CoupleShellState();
}

class _CoupleShellState extends State<CoupleShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return ShellScaffold(
      scaffoldKey: _scaffoldKey,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: const AppDrawer(),
        body: widget.navigationShell,
      ),
    );
  }
}
