import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  static const List<String> glyphFallback = [
    'Noto Color Emoji',
    'Noto Sans Symbols',
    'Segoe UI Emoji',
    'Segoe UI Symbol',
  ];

  static TextStyle withGlyphFallback(TextStyle style) => style.copyWith(
        fontFamilyFallback: [...?style.fontFamilyFallback, ...glyphFallback],
      );

  static TextStyle get displayLarge => withGlyphFallback(TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ));

  static TextStyle get displayMedium => withGlyphFallback(TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ));

  static TextStyle get displaySmall => withGlyphFallback(TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ));

  static TextStyle get headlineLarge => withGlyphFallback(TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ));

  static TextStyle get headlineMedium => withGlyphFallback(TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ));

  static TextStyle get headlineSmall => withGlyphFallback(TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ));

  static TextStyle get titleLarge => withGlyphFallback(TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ));

  static TextStyle get titleMedium => withGlyphFallback(TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ));

  static TextStyle get bodyLarge => withGlyphFallback(TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ));

  static TextStyle get bodyMedium => withGlyphFallback(TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ));

  static TextStyle get bodySmall => withGlyphFallback(TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ));

  static TextStyle get labelLarge => withGlyphFallback(TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ));

  static TextStyle get labelMedium => withGlyphFallback(TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ));

  static TextStyle get caption => withGlyphFallback(TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.normal,
      ));

  static TextStyle get buttonText => withGlyphFallback(TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ));

  static TextStyle get priceTag => withGlyphFallback(TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ));
}
