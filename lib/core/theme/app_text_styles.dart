import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  static TextStyle get displayLarge => withGlyphFallback(GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ));

  static TextStyle get displayMedium => withGlyphFallback(GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        height: 1.3,
      ));

  static TextStyle get displaySmall => withGlyphFallback(GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ));

  static TextStyle get headlineLarge => withGlyphFallback(GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ));

  static TextStyle get headlineMedium => withGlyphFallback(GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ));

  static TextStyle get headlineSmall => withGlyphFallback(GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ));

  static TextStyle get titleLarge => withGlyphFallback(GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ));

  static TextStyle get titleMedium => withGlyphFallback(GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ));

  static TextStyle get bodyLarge => withGlyphFallback(GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ));

  static TextStyle get bodyMedium => withGlyphFallback(GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ));

  static TextStyle get bodySmall => withGlyphFallback(GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
      ));

  static TextStyle get labelLarge => withGlyphFallback(GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ));

  static TextStyle get labelMedium => withGlyphFallback(GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.3,
      ));

  static TextStyle get caption => withGlyphFallback(GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.normal,
      ));

  static TextStyle get buttonText => withGlyphFallback(GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ));

  static TextStyle get priceTag => withGlyphFallback(GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ));
}
