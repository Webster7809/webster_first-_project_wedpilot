import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wed_plan_pilot/widgets/section_header.dart';

void main() {
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
}
