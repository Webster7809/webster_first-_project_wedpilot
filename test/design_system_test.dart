import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wed_plan_pilot/core/theme/app_colors.dart';
import 'package:wed_plan_pilot/core/theme/app_text_styles.dart';
import 'package:wed_plan_pilot/core/theme/app_theme.dart';

/// Relative luminance per WCAG 2.1.
double _luminance(Color c) {
  double channel(double v) => v <= 0.03928
      ? v / 12.92
      : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel((c.r * 255.0).round() / 255) +
      0.7152 * channel((c.g * 255.0).round() / 255) +
      0.0722 * channel((c.b * 255.0).round() / 255);
}

double contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('typefaces are real', () {
    // The whole app rendered in Roboto because the scale declared sizes but
    // never a family. These assertions are the tripwire for that regressing.
    test('serif carries display and headline', () {
      for (final style in [
        AppTextStyles.displayLarge,
        AppTextStyles.displayMedium,
        AppTextStyles.displaySmall,
        AppTextStyles.headlineLarge,
        AppTextStyles.sectionTitle,
      ]) {
        expect(style.fontFamily, AppTextStyles.serif);
      }
    });

    test('sans carries body, labels and every numeric', () {
      for (final style in [
        AppTextStyles.bodyLarge,
        AppTextStyles.bodyMedium,
        AppTextStyles.bodySmall,
        AppTextStyles.labelLarge,
        AppTextStyles.buttonText,
        AppTextStyles.figure,
        AppTextStyles.priceTag,
        AppTextStyles.dataMedium,
      ]) {
        expect(style.fontFamily, AppTextStyles.sans);
      }
    });

    test('figures are tabular so columns align', () {
      for (final style in [
        AppTextStyles.figure,
        AppTextStyles.priceTag,
        AppTextStyles.dataMedium,
      ]) {
        expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
      }
    });

    test('font files are actually bundled', () async {
      // Guards the failure this replaced: a family named in code but never
      // shipped falls back to Roboto silently.
      for (final asset in const [
        'assets/fonts/PlayfairDisplay-SemiBold.ttf',
        'assets/fonts/PlayfairDisplay-Bold.ttf',
        'assets/fonts/Inter-Regular.ttf',
        'assets/fonts/Inter-Medium.ttf',
        'assets/fonts/Inter-SemiBold.ttf',
        'assets/fonts/Inter-Bold.ttf',
      ]) {
        final data = await rootBundle.load(asset);
        expect(data.lengthInBytes, greaterThan(1000), reason: '$asset is empty');
      }
    });
  });

  group('the scale exists in one place', () {
    test('TextTheme is derived from AppTextStyles, not restated', () {
      final text = AppTheme.light.textTheme;
      expect(text.displayLarge!.fontSize, AppTextStyles.displayLarge.fontSize);
      expect(text.displayLarge!.fontFamily, AppTextStyles.serif);
      expect(text.bodyMedium!.fontSize, AppTextStyles.bodyMedium.fontSize);
      expect(text.bodyMedium!.fontFamily, AppTextStyles.sans);
      expect(text.labelLarge!.fontWeight, AppTextStyles.labelLarge.fontWeight);
    });
  });

  group('contrast holds up outdoors', () {
    test('primary CTA is AAA, not the 2.42:1 gold it used to be', () {
      expect(contrast(Colors.white, AppColors.primary), greaterThan(7.0));
    });

    test('a gold fill never takes a white foreground', () {
      // White on gold is 2.42:1. Ink on gold is 6.44:1.
      expect(contrast(AppColors.textOnSecondary, AppColors.gold),
          greaterThanOrEqualTo(4.5));
      expect(contrast(Colors.white, AppColors.gold), lessThan(3.0),
          reason: 'if this ever passes, gold changed — recheck every gold fill');
    });

    test('body and secondary text clear AA on both grounds', () {
      for (final ground in [AppColors.cream, AppColors.surface]) {
        expect(contrast(AppColors.textPrimary, ground), greaterThan(7.0));
        expect(contrast(AppColors.textSecondary, ground),
            greaterThanOrEqualTo(4.5));
      }
    });

    test('hint clears the 3:1 non-text threshold', () {
      expect(contrast(AppColors.textHint, AppColors.cream), greaterThan(3.0));
    });

    test('semantic tones clear AA on cream and on their own tint', () {
      final pairs = {
        AppColors.success: AppColors.successBg,
        AppColors.error: AppColors.errorBg,
        AppColors.info: AppColors.infoBg,
      };
      pairs.forEach((fg, tint) {
        expect(contrast(fg, AppColors.cream), greaterThanOrEqualTo(4.5));
        expect(contrast(fg, tint), greaterThanOrEqualTo(4.5));
      });
      // Warning is the one tone that only clears large-text AA; it is used for
      // chips and icons, never small body copy.
      expect(contrast(AppColors.warning, AppColors.cream), greaterThan(3.0));
    });

    test('goldDeep is usable where gold is not', () {
      expect(contrast(AppColors.goldDeep, AppColors.cream), greaterThan(3.0));
      expect(contrast(AppColors.goldDeep, AppColors.surface), greaterThan(4.5));
    });

    test('gold leads in dark theme, where it clears AAA', () {
      expect(contrast(AppColors.gold, AppColors.darkBackground),
          greaterThan(7.0));
      expect(contrast(AppColors.darkText, AppColors.darkBackground),
          greaterThan(7.0));
      expect(contrast(AppColors.darkTextSecondary, AppColors.darkSurface),
          greaterThanOrEqualTo(4.5));
    });
  });

  group('tokens and ColorScheme agree', () {
    test('colorScheme.primary is the same color as AppColors.primary', () {
      // These used to disagree — the scheme said gold, the tokens said forest —
      // so a widget reading the theme got the opposite of one reading tokens.
      expect(AppTheme.light.colorScheme.primary, AppColors.primary);
      expect(AppTheme.light.colorScheme.secondary, AppColors.gold);
    });

    test('onSecondary is ink, so a gold fill is always legible', () {
      final scheme = AppTheme.light.colorScheme;
      expect(contrast(scheme.onSecondary, scheme.secondary),
          greaterThanOrEqualTo(4.5));
    });

    test('elevated buttons are forest, not gold', () {
      final style = AppTheme.light.elevatedButtonTheme.style!;
      final bg = style.backgroundColor!.resolve({});
      final fg = style.foregroundColor!.resolve({});
      expect(bg, AppColors.primary);
      expect(contrast(fg!, bg!), greaterThan(7.0));
    });
  });
}
