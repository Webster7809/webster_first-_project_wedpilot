import 'package:flutter/material.dart';

/// The single source of truth for type.
///
/// [AppTheme] builds its [TextTheme] from these getters rather than restating
/// them, so a size or weight changes in exactly one place.
///
/// ## Which face
///
/// * **Playfair Display** (serif) — [displayLarge] through [headlineLarge] and
///   [sectionTitle]. The floor is 20px: below that Playfair's high stroke
///   contrast costs legibility on a mid-range Android screen in daylight.
/// * **Inter** (sans) — everything else. All body copy, labels, buttons, and
///   every numeric.
///
/// Numbers are never set in the serif. Anything that lines up in a column
/// ([figure], [priceTag], [dataMedium]) uses tabular figures so digits align.
///
/// Both families are bundled assets (see `pubspec.yaml`), not runtime fetches.
class AppTextStyles {
  AppTextStyles._();

  static const String serif = 'Playfair Display';
  static const String sans = 'Inter';

  static const List<String> glyphFallback = [
    'Noto Color Emoji',
    'Noto Sans Symbols',
    'Segoe UI Emoji',
    'Segoe UI Symbol',
  ];

  static TextStyle withGlyphFallback(TextStyle style) => style.copyWith(
        fontFamilyFallback: [...?style.fontFamilyFallback, ...glyphFallback],
      );

  static TextStyle _serif({
    required double size,
    FontWeight weight = FontWeight.w600,
    double? height,
    double? letterSpacing,
  }) =>
      withGlyphFallback(TextStyle(
        fontFamily: serif,
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
      ));

  static TextStyle _sans({
    required double size,
    FontWeight weight = FontWeight.normal,
    double? height,
    double? letterSpacing,
    FontFeature? feature,
  }) =>
      withGlyphFallback(TextStyle(
        fontFamily: sans,
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
        fontFeatures: feature == null ? null : [feature],
      ));

  // ── Display / headline — Playfair Display ───────────────────────────────────
  static TextStyle get displayLarge =>
      _serif(size: 32, weight: FontWeight.w700, height: 1.15, letterSpacing: -0.3);

  static TextStyle get displayMedium =>
      _serif(size: 26, height: 1.2, letterSpacing: -0.2);

  static TextStyle get displaySmall => _serif(size: 22, height: 1.25);

  static TextStyle get headlineLarge => _serif(size: 20, height: 1.3);

  /// Section heading, paired with the gold hairline in [WedSectionHeader].
  static TextStyle get sectionTitle => _serif(size: 19, height: 1.3);

  // ── Titles and below — Inter ────────────────────────────────────────────────
  static TextStyle get headlineMedium =>
      _sans(size: 18, weight: FontWeight.w600, height: 1.35);

  static TextStyle get headlineSmall =>
      _sans(size: 16, weight: FontWeight.w600, height: 1.4);

  /// Alias for [headlineSmall] — used by widgets that name it "subheading".
  static TextStyle get subheading => headlineSmall;

  static TextStyle get titleLarge => _sans(size: 16, weight: FontWeight.w500, height: 1.4);

  static TextStyle get titleMedium => _sans(size: 14, weight: FontWeight.w500, height: 1.4);

  // ── Body — Inter ────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => _sans(size: 16, height: 1.5);

  static TextStyle get bodyMedium => _sans(size: 14, height: 1.5);

  /// Alias for [bodyMedium] — used by widgets that name it "body".
  static TextStyle get body => bodyMedium;

  static TextStyle get bodySmall => _sans(size: 12, height: 1.45);

  // ── Labels — Inter ──────────────────────────────────────────────────────────
  static TextStyle get labelLarge =>
      _sans(size: 14, weight: FontWeight.w600, letterSpacing: 0.5);

  /// Alias for [labelLarge] — used by widgets that name it "label".
  static TextStyle get label => labelLarge;

  static TextStyle get labelMedium =>
      _sans(size: 12, weight: FontWeight.w500, letterSpacing: 0.3);

  /// Small all-caps eyebrow above a group of fields or a stat.
  static TextStyle get overline => _sans(
        size: 11,
        weight: FontWeight.w600,
        letterSpacing: 1.0,
        height: 1.3,
      );

  static TextStyle get caption => _sans(size: 11, height: 1.4);

  static TextStyle get buttonText =>
      _sans(size: 15, weight: FontWeight.w600, letterSpacing: 0.2);

  /// Alias for [buttonText] — used by widgets that name it "button".
  static TextStyle get button => buttonText;

  // ── Numerics — Inter, tabular ───────────────────────────────────────────────
  static const FontFeature _tabular = FontFeature.tabularFigures();

  /// Large figure for a dashboard stat — budget remaining, guest count.
  static TextStyle get figure => _sans(
        size: 28,
        weight: FontWeight.w600,
        height: 1.15,
        letterSpacing: -0.4,
        feature: _tabular,
      );

  static TextStyle get priceTag =>
      _sans(size: 18, weight: FontWeight.w700, feature: _tabular);

  /// Aligned numerics inside a table or list row.
  static TextStyle get dataMedium =>
      _sans(size: 14, weight: FontWeight.w500, feature: _tabular);
}
