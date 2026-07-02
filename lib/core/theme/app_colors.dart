import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand palette ───────────────────────────────────────────────────────────
  static const forestGreen = Color(0xFF1B3A2D);   // Dark forest green — primary brand
  static const amber = Color(0xFFC9892B);           // Warm golden amber — accent / CTA
  static const cream = Color(0xFFF5EFE6);           // Warm cream — scaffold background
  static const creamDark = Color(0xFFEAE2D8);      // Slightly deeper cream

  // ── Semantic aliases ────────────────────────────────────────────────────────
  static const primary = forestGreen;
  static const secondary = amber;       // alias for amber
  static const tertiary = Color(0xFF2A7B5B);
  static const accent = amber;          // alias for amber
  static const background = cream;
  static const surface = Color(0xFFFFFFFF);
  static const neutralDark = Color(0xFF374151);
  static const roseGoldPremium = amber; // alias for amber

  // ── Text ────────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF767676);
  static const textHint = Color(0xFFAFAFAF);
  static const textOnPrimary = Color(0xFFFFFFFF);
  static const textOnSecondary = Color(0xFFFFFFFF);

  // ── Status ──────────────────────────────────────────────────────────────────
  static const success = Color(0xFF2A7B5B);
  static const successBg = Color(0xFFE4F3EC);
  static const warning = Color(0xFFE8921A);
  static const warningBg = Color(0xFFFEF0E7);
  static const error = Color(0xFFD44242);
  static const errorBg = Color(0xFFFEECEC);
  static const info = Color(0xFF1976D2);
  static const infoBg = Color(0xFFE3F2FD);

  // ── Vendor verification states ──────────────────────────────────────────────
  static const verified = Color(0xFF2A7B5B);
  static const verifiedBg = Color(0xFFE4F3EC);
  static const pending = Color(0xFFE8921A);
  static const pendingBg = Color(0xFFFEF0E7);
  static const flagged = Color(0xFFD44242);
  static const flaggedBg = Color(0xFFFEECEC);

  // ── Budget chart segments ───────────────────────────────────────────────────
  static const budgetCatering = Color(0xFFF4C561);
  static const budgetDecor = forestGreen;
  static const budgetUnallocated = Color(0xFFDDD6CB);
  static const budgetGreen = Color(0xFF2A7B5B);
  static const budgetAmber = Color(0xFFF4C561);
  static const budgetRed = Color(0xFFD44242);
  static const goldPremium = amber;     // alias for amber

  static const budgetCategoryColors = <String, Color>{
    'Venue': Color(0xFFC9892B),
    'Catering': Color(0xFFD4A017),
    'Photography': Color(0xFF4A8B6F),
    'Decor & flowers': forestGreen,
    'DJ & MC': Color(0xFF6B9E8A),
    'Transport': Color(0xFF8BAE9E),
    'Wedding attire': Color(0xFF7B8E7A),
    'Cake & sweets': Color(0xFFB5916A),
  };

  // ── Structural ───────────────────────────────────────────────────────────────
  static const divider = Color(0xFFDDD6CB);
  static const cardShadow = Color(0x14000000);
  static const shimmerBase = Color(0xFFE8E0D5);
  static const shimmerHighlight = Color(0xFFF5EFE6);
  static const progressTrack = Color(0xFFEEEBE4);     // progress bar background
  static const segmentedBarTrack = Color(0xFFE0DDD6); // dashboard segmented bar

  // ── Role color aliases ───────────────────────────────────────────────────────
  static const coupleMagenta = Color(0xFF2A5C3F);
  static const vendorIndigo = Color(0xFF2A5C3F);
  static const vendorGreen = Color(0xFF2A7B5B);
  static const vendorGreenMid = Color(0xFF3D9B72);

  // ── Dark theme ──────────────────────────────────────────────────────────────
  static const darkBackground = Color(0xFF111318);
  static const darkSurface = Color(0xFF1C1F26);
  static const darkSurfaceVariant = Color(0xFF252830);
  static const darkText = Color(0xFFEAEAEA);
  static const darkTextSecondary = Color(0xFF9E9E9E);
  static const darkDivider = Color(0xFF2C2E35);

  // ── Misc UI ─────────────────────────────────────────────────────────────────
  static const teal = Color(0xFF2A9D8F);
  static const adminPinkLight = Color(0xFFF06292);
  static const inputFillAlt = Color(0xFFF7F7F7);

  // ── Admin panel ─────────────────────────────────────────────────────────────
  static const adminPage = Color(0xFFF5EFE6);
  static const adminSidebar = forestGreen;
  static const adminGreen = Color(0xFF2A7B5B);
  static const adminGreenBg = Color(0xFFE4F3EC);
  static const adminNeutral = Color(0xFF374151);
  static const adminNeutralBg = Color(0xFFF1F3F4);
  static const adminAmber = amber;
  static const adminAmberBg = Color(0xFFFEF0E7);
  static const adminBlue = Color(0xFF1E88E5);
  static const adminBlueBg = Color(0xFFE3F2FD);
  static const adminIndigo = Color(0xFF3949AB);
  static const adminIndigoBg = Color(0xFFE8EAF6);
  static const adminPink = Color(0xFFE91E63);
  static const adminPinkBg = Color(0xFFFCE4EC);
  static const adminRedBg = Color(0xFFFEECEC);
}
