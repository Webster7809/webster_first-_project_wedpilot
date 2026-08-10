import 'package:flutter/material.dart';

/// The single source of truth for color.
///
/// ## Using gold
///
/// Gold is asymmetric between themes and the rule is easy to break by accident:
///
/// * **Light theme** — [gold] is a *fill and hairline color only*. On the cream
///   ground it reaches 2.12:1, so it can never carry text or a meaningful icon.
///   When you need gold-colored text on cream, use [goldDeep] (4.25:1) and only
///   at 18px or larger. Below that, use [textPrimary] or [forestGreen].
/// * **Dark theme** — gold reaches 7.73:1 on [darkBackground], so it *is* a
///   legitimate text and heading color there. See [goldOn] to pick correctly
///   without hardcoding the check.
///
/// A gold *fill* (button, chip, badge) must carry [textPrimary] or
/// [forestGreen] as its foreground — never white, which is 2.42:1.
///
/// Primary CTAs are [forestGreen] with white text (12.08:1). Gold is the
/// accent, not the button color; a gold-filled button on every screen is what
/// made the old UI read generic.
class AppColors {
  AppColors._();

  // ── Brand palette ───────────────────────────────────────────────────────────
  static const forestGreen = Color(0xFF163D2C); // Deep forest — primary brand
  static const forestDeep = Color(0xFF0F2C1F);  // Pressed/active forest surfaces
  static const gold = Color(0xFFC9A227);        // Warm gold — accent, fills only (light)
  static const goldDeep = Color(0xFF8A6E19);    // The only gold usable as text on cream, ≥18px
  static const goldSoft = Color(0xFFF7EFD4);    // Gold tint background
  static const cream = Color(0xFFF5EFE6);       // Warm cream — scaffold background
  static const creamDark = Color(0xFFEAE2D8);   // Slightly deeper cream — tracks, wells

  /// Deprecated spelling of [gold], kept so existing call sites keep compiling.
  /// Prefer [gold] in new code.
  static const amber = gold;

  // ── Semantic aliases ────────────────────────────────────────────────────────
  static const primary = forestGreen;
  static const secondary = gold;
  static const tertiary = Color(0xFF2A7B5B);
  static const accent = gold;
  static const accentText = goldDeep; // gold-as-text on cream must be the deep tone
  static const accentSoft = goldSoft;
  static const background = cream;
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = creamDark;
  static const neutralDark = Color(0xFF374151);
  static const roseGoldPremium = gold;

  // ── Text ────────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFF1C2620);   // Green-black ink — 13.63:1 on cream
  static const textSecondary = Color(0xFF5F6862); // Muted — 5.04:1 on cream (AA)
  static const textHint = Color(0xFF767E78);      // Placeholder/disabled only — 3.66:1
  static const textOnPrimary = Color(0xFFFFFFFF); // On forestGreen — 12.08:1
  static const textOnSecondary = textPrimary;     // On a gold fill — 6.44:1, never white
  static const textDark = textPrimary;
  static const textMid = textSecondary;
  static const textMuted = textSecondary;

  /// Gold that is safe to render as text on the current theme's ground: the
  /// deep tone in light, the full accent in dark.
  static Color goldOn(Brightness brightness) =>
      brightness == Brightness.dark ? gold : goldDeep;

  // ── Status ──────────────────────────────────────────────────────────────────
  // Each tone clears AA both on cream and on its own tint, so a status chip and
  // status text can share one token.
  static const success = Color(0xFF1F6B4D);
  static const successBg = Color(0xFFE4F3EC);
  static const warning = Color(0xFFA6690B); // browner than gold, so it never reads as the accent
  static const warningBg = Color(0xFFFDF0DE);
  static const error = Color(0xFFB33023);
  static const errorBg = Color(0xFFFCEBE9);
  static const errorSoft = errorBg;
  static const info = Color(0xFF1F6FB2);
  static const infoBg = Color(0xFFE3F0FA);

  // ── Vendor verification states ──────────────────────────────────────────────
  static const verified = success;
  static const verifiedBg = successBg;
  static const pending = warning;
  static const pendingBg = warningBg;
  static const flagged = error;
  static const flaggedBg = errorBg;

  // ── Budget chart segments ───────────────────────────────────────────────────
  // Chart fills, not text — they only need to be distinguishable from each
  // other and from the cream ground.
  static const budgetCatering = Color(0xFFD9B23F);
  static const budgetDecor = forestGreen;
  static const budgetUnallocated = Color(0xFFDDD6CB);
  static const budgetGreen = success;
  static const budgetAmber = Color(0xFFD9B23F);
  static const budgetRed = error;
  static const goldPremium = gold;

  static const budgetCategoryColors = <String, Color>{
    'Venue': gold,
    'Catering': Color(0xFFD9B23F),
    'Photography': Color(0xFF4A8B6F),
    'Decor & flowers': forestGreen,
    'DJ & MC': Color(0xFF6B9E8A),
    'Transport': Color(0xFF8BAE9E),
    'Wedding attire': Color(0xFF7B8E7A),
    'Cake & sweets': Color(0xFFB5916A),
  };

  // ── Structural ───────────────────────────────────────────────────────────────
  static const divider = Color(0xFFDDD6CB);
  static const dividerStrong = Color(0xFFC9BFB0);
  static const cardShadow = Color(0x14163D2C);
  static const shimmerBase = Color(0xFFE8E0D5);
  static const shimmerHighlight = cream;
  static const progressTrack = Color(0xFFEEEBE4);
  static const segmentedBarTrack = Color(0xFFE0DDD6);

  // ── Role color aliases ───────────────────────────────────────────────────────
  static const gradientAccentGreen = Color(0xFF275540);
  static const vendorGreen = Color(0xFF2A7B5B);
  static const vendorGreenMid = Color(0xFF3D9B72);

  // ── Dark theme ──────────────────────────────────────────────────────────────
  // Warm-shifted to stay in the brand's world — a cool blue-grey dark theme
  // reads as a different product than the cream light theme.
  static const darkBackground = Color(0xFF14120F);
  static const darkSurface = Color(0xFF1E1B17);
  static const darkSurfaceVariant = Color(0xFF272320);
  static const darkText = Color(0xFFF2EDE4);          // 16.03:1 on darkBackground
  static const darkTextSecondary = Color(0xFFA29B90); // 6.79:1
  static const darkTextHint = Color(0xFF8A837A);
  static const darkDivider = Color(0xFF332E29);
  static const darkSuccess = Color(0xFF7FC4A3);
  static const darkError = Color(0xFFF08A7E);
  static const darkWarning = Color(0xFFDCA53F);

  // ── Misc UI ─────────────────────────────────────────────────────────────────
  static const teal = Color(0xFF2A9D8F);
  static const adminPinkLight = Color(0xFFF06292);
  static const inputFillAlt = Color(0xFFF7F7F7);
  static const sageGold = Color(0xFFD4A854); // matches invitation "Sage Gold" swatch

  // ── Admin panel ─────────────────────────────────────────────────────────────
  static const adminPage = cream;
  static const adminSidebar = forestGreen;
  static const adminGreen = success;
  static const adminGreenBg = successBg;
  static const adminNeutral = Color(0xFF374151);
  static const adminNeutralBg = Color(0xFFF1F3F4);
  static const adminAmber = warning;
  static const adminAmberBg = warningBg;
  static const adminBlue = info;
  static const adminBlueBg = infoBg;
  static const adminIndigo = Color(0xFF3949AB);
  static const adminIndigoBg = Color(0xFFE8EAF6);
  static const adminPink = Color(0xFFC2185B);
  static const adminPinkBg = Color(0xFFFCE4EC);
  static const adminRedBg = errorBg;
}
