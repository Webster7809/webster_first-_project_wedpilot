import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wed_plan_pilot/widgets/section_header.dart';
import 'package:wed_plan_pilot/widgets/shell_nav_item.dart';

void main() {
  testWidgets('ShellNavItem renders without overflow in a narrow container', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 64,
              child: Column(
                children: [
                  ShellNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Very long nav label',
                    index: 0,
                    currentIndex: 0,
                    onTap: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'SectionHeader keeps title and action label inside the available width',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 220,
                child: SectionHeader(
                  title:
                      'A very long section title that should shrink gracefully',
                  actionLabel: 'View all',
                  onAction: () {},
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('ShellNavItem stays within a short container height', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  ShellNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Home',
                    index: 0,
                    currentIndex: 0,
                    onTap: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
