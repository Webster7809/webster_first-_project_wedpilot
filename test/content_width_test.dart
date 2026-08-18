import 'package:flutter_test/flutter_test.dart';
import 'package:wed_plan_pilot/core/theme/app_dimensions.dart';

/// Page content has to stop growing at some point. Without a cap, a vendor
/// profile on a laptop renders its description, packages and reviews as one
/// line running the full window — the "stretched, edge to edge" look.
///
/// Only one screen in the app used `contentMaxWidth` before this; the helper
/// exists so the rest can adopt it without each inventing its own arithmetic.
void main() {
  group('AppDimensions.gutter', () {
    test('phones keep their normal edge padding', () {
      expect(AppDimensions.gutter(320), 20);
      expect(AppDimensions.gutter(390), 20);
      expect(AppDimensions.gutter(412), 20);
    });

    test('content is centred once the window exceeds contentMaxWidth', () {
      // 1440 - 900 = 540 of surplus, split evenly either side.
      expect(AppDimensions.gutter(1440), 270);
      expect(1440 - 2 * AppDimensions.gutter(1440),
          AppDimensions.contentMaxWidth);
    });

    test('an ultrawide window still caps the content, not the gutter', () {
      expect(2560 - 2 * AppDimensions.gutter(2560),
          AppDimensions.contentMaxWidth);
    });

    test('just above the cap, the minimum gutter still wins', () {
      // 920 would give a 10px gutter on its own — thinner than the phone
      // padding, which would look like a bug rather than a layout.
      expect(AppDimensions.gutter(920), 20);
    });

    test('minGutter and maxContent are overridable per screen', () {
      expect(AppDimensions.gutter(390, minGutter: 16), 16);
      expect(
        1000 - 2 * AppDimensions.gutter(1000, maxContent: 600),
        600,
      );
    });

    test('never returns a negative gutter', () {
      expect(AppDimensions.gutter(100), greaterThanOrEqualTo(0));
    });
  });
}
