import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_text_styles.dart';

/// Light and dark [ThemeData] for the app.
///
/// The text theme is *derived* from [AppTextStyles] rather than restated here
/// — that duplication used to mean every size lived in two places and drifted.
/// To change a size or weight, edit [AppTextStyles] only.
///
/// [ColorScheme.primary] is forest green, matching [AppColors.primary]. Those
/// two used to disagree — the scheme said gold, the tokens said forest — so a
/// widget reading the theme got the opposite color from one reading the
/// tokens. Gold is [ColorScheme.secondary], and anything filled with it takes
/// [AppColors.textOnSecondary] (ink), never white.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final text = _textTheme(AppColors.textPrimary, AppColors.textSecondary);
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.sans,
      colorScheme: const ColorScheme.light(
        primary: AppColors.forestGreen,
        onPrimary: Colors.white,
        primaryContainer: AppColors.forestDeep,
        onPrimaryContainer: Colors.white,
        secondary: AppColors.gold,
        onSecondary: AppColors.textPrimary,
        secondaryContainer: AppColors.goldSoft,
        onSecondaryContainer: AppColors.textPrimary,
        tertiary: AppColors.tertiary,
        onTertiary: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.creamDark,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.dividerStrong,
        outlineVariant: AppColors.divider,
        error: AppColors.error,
        onError: Colors.white,
        errorContainer: AppColors.errorBg,
        onErrorContainer: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: text,
      // No iconTheme/titleTextStyle here on purpose. AppBar resolves those as
      // `widget.iconTheme ?? appBarTheme.iconTheme ?? defaults(foregroundColor)`
      // (see AppBar.build), so setting them here would win over a screen's own
      // `foregroundColor:` and leave near-black icons and title on the forest
      // app bars ~21 screens use. Leaving them unset lets foregroundColor
      // drive both; the Playfair face comes from textTheme.titleLarge, which
      // is what AppBar falls back to.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          // Forest, not gold: white on gold is 2.42:1, white on forest 12.08:1.
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(88, 48),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.bbutton),
          textStyle: AppTextStyles.buttonText,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(88, 48),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.bbutton),
          textStyle: AppTextStyles.buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      inputDecorationTheme: _inputTheme(
        fill: AppColors.surface,
        border: AppColors.divider,
        focus: AppColors.primary,
        error: AppColors.error,
        hint: AppColors.textHint,
        label: AppColors.textSecondary,
      ),
      // Elevation 0 — a card's lift comes from AppShadows via WedCard, not from
      // a stock Material drop shadow.
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: AppColors.cardShadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.creamDark,
        selectedColor: AppColors.gold,
        labelStyle: AppTextStyles.labelMedium
            .copyWith(color: AppColors.textPrimary),
        secondaryLabelStyle: AppTextStyles.labelMedium
            .copyWith(color: AppColors.textOnSecondary),
        side: const BorderSide(color: AppColors.divider),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.goldSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) =>
            AppTextStyles.caption.copyWith(
              fontWeight:
                  states.contains(WidgetState.selected) ? FontWeight.w600 : null,
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.textSecondary,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.textSecondary,
            )),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.forestGreen,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        actionTextColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.progressTrack,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorColor: AppColors.gold,
        labelStyle: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextStyles.titleMedium,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      switchTheme: _switchTheme(
        on: AppColors.primary,
        offThumb: AppColors.surface,
        offTrack: AppColors.creamDark,
      ),
      checkboxTheme: _checkboxTheme(AppColors.primary, AppColors.dividerStrong),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.primary
                : AppColors.dividerStrong),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: AppColors.textSecondary,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.top(AppRadius.bottomSheet),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle:
            AppTextStyles.displaySmall.copyWith(color: AppColors.textPrimary),
        contentTextStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final text = _textTheme(AppColors.darkText, AppColors.darkTextSecondary);
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppTextStyles.sans,
      colorScheme: const ColorScheme.dark(
        // Gold clears AAA on the dark ground (7.73:1), so it leads here where
        // it cannot in light theme.
        primary: AppColors.gold,
        onPrimary: AppColors.textPrimary,
        primaryContainer: AppColors.darkSurfaceVariant,
        onPrimaryContainer: AppColors.gold,
        secondary: AppColors.vendorGreenMid,
        onSecondary: AppColors.textPrimary,
        tertiary: AppColors.tertiary,
        onTertiary: Colors.white,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkText,
        surfaceContainerHighest: AppColors.darkSurfaceVariant,
        onSurfaceVariant: AppColors.darkTextSecondary,
        outline: AppColors.darkDivider,
        outlineVariant: AppColors.darkDivider,
        error: AppColors.darkError,
        onError: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: text,
      // See the light theme's appBarTheme — iconTheme/titleTextStyle are
      // deliberately unset so a screen's own foregroundColor drives both.
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(88, 48),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.bbutton),
          textStyle: AppTextStyles.buttonText,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.gold,
          minimumSize: const Size(88, 48),
          side: const BorderSide(color: AppColors.gold, width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.bbutton),
          textStyle: AppTextStyles.buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.gold,
          textStyle: AppTextStyles.labelLarge,
        ),
      ),
      inputDecorationTheme: _inputTheme(
        fill: AppColors.darkSurfaceVariant,
        border: AppColors.darkDivider,
        focus: AppColors.gold,
        error: AppColors.darkError,
        hint: AppColors.darkTextHint,
        label: AppColors.darkTextSecondary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.darkDivider),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        selectedColor: AppColors.gold,
        labelStyle:
            AppTextStyles.labelMedium.copyWith(color: AppColors.darkText),
        secondaryLabelStyle:
            AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary),
        side: const BorderSide(color: AppColors.darkDivider),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.gold.withAlpha(51),
        labelTextStyle: WidgetStateProperty.resolveWith((states) =>
            AppTextStyles.caption.copyWith(
              fontWeight:
                  states.contains(WidgetState.selected) ? FontWeight.w600 : null,
              color: states.contains(WidgetState.selected)
                  ? AppColors.gold
                  : AppColors.darkTextSecondary,
            )),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.gold
                  : AppColors.darkTextSecondary,
            )),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkSurfaceVariant,
        contentTextStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.darkText),
        actionTextColor: AppColors.gold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.gold,
        linearTrackColor: AppColors.darkSurfaceVariant,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.gold,
        unselectedLabelColor: AppColors.darkTextSecondary,
        indicatorColor: AppColors.gold,
        labelStyle: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextStyles.titleMedium,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.textPrimary,
        elevation: 2,
      ),
      switchTheme: _switchTheme(
        on: AppColors.gold,
        offThumb: AppColors.darkTextSecondary,
        offTrack: AppColors.darkSurfaceVariant,
      ),
      checkboxTheme: _checkboxTheme(AppColors.gold, AppColors.darkDivider,
          check: AppColors.textPrimary),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected)
                ? AppColors.gold
                : AppColors.darkDivider),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: AppColors.darkTextSecondary,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.top(AppRadius.bottomSheet),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.darkSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle:
            AppTextStyles.displaySmall.copyWith(color: AppColors.darkText),
        contentTextStyle: AppTextStyles.bodyMedium
            .copyWith(color: AppColors.darkTextSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
      ),
    );
  }

  // ── Shared builders ─────────────────────────────────────────────────────────

  static InputDecorationTheme _inputTheme({
    required Color fill,
    required Color border,
    required Color focus,
    required Color error,
    required Color hint,
    required Color label,
  }) {
    OutlineInputBorder side(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecorationTheme(
      filled: true,
      fillColor: fill,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: side(border),
      enabledBorder: side(border),
      focusedBorder: side(focus, 2),
      errorBorder: side(error),
      focusedErrorBorder: side(error, 2),
      hintStyle: AppTextStyles.bodyMedium.copyWith(color: hint),
      labelStyle: AppTextStyles.bodyMedium.copyWith(color: label),
      floatingLabelStyle: AppTextStyles.labelMedium.copyWith(color: focus),
      errorStyle: AppTextStyles.caption.copyWith(color: error),
    );
  }

  static SwitchThemeData _switchTheme({
    required Color on,
    required Color offThumb,
    required Color offTrack,
  }) =>
      SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.white : offThumb),
        trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? on : offTrack),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? on : offThumb),
      );

  static CheckboxThemeData _checkboxTheme(Color on, Color border,
          {Color check = Colors.white}) =>
      CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? on : Colors.transparent),
        checkColor: WidgetStateProperty.all(check),
        side: BorderSide(color: border, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      );

  /// Derived from [AppTextStyles] so the scale exists in exactly one place.
  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(color: primary),
      displayMedium: AppTextStyles.displayMedium.copyWith(color: primary),
      displaySmall: AppTextStyles.displaySmall.copyWith(color: primary),
      headlineLarge: AppTextStyles.headlineLarge.copyWith(color: primary),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(color: primary),
      headlineSmall: AppTextStyles.headlineSmall.copyWith(color: primary),
      // Playfair, not Inter: this is the slot AppBar falls back to for its
      // title (defaults.titleTextStyle = textTheme.titleLarge), and app bar
      // titles are a display surface. Carrying the face here rather than in
      // appBarTheme.titleTextStyle is what lets each screen's foregroundColor
      // still set the colour. Nothing else in the app reads this slot.
      titleLarge: AppTextStyles.headlineLarge.copyWith(color: primary),
      titleMedium: AppTextStyles.titleMedium.copyWith(color: primary),
      titleSmall: AppTextStyles.labelMedium.copyWith(color: primary),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: primary),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: primary),
      bodySmall: AppTextStyles.bodySmall.copyWith(color: secondary),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: primary),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: secondary),
      labelSmall: AppTextStyles.caption.copyWith(color: secondary),
    );
  }
}
