import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.forestGreen,
          primary: AppColors.amber,
          secondary: AppColors.forestGreen,
          tertiary: AppColors.tertiary,
          surface: AppColors.surface,
          error: AppColors.error,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.textPrimary,
        ),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: _buildTextTheme(AppColors.textPrimary, AppColors.textSecondary),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            foregroundColor: Colors.white,
            minimumSize: const Size(88, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.secondary,
            minimumSize: const Size(88, 48),
            side: const BorderSide(color: AppColors.secondary, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.secondary,
            textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.secondary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
          hintStyle: GoogleFonts.inter(color: AppColors.textHint, fontSize: 14),
          labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
          floatingLabelStyle: GoogleFonts.inter(color: AppColors.secondary, fontSize: 12),
        ),
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 2,
          shadowColor: AppColors.cardShadow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.primary.withAlpha(76),
          selectedColor: AppColors.secondary,
          labelStyle: GoogleFonts.inter(fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withAlpha(128),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary);
            }
            return GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.secondary);
            }
            return const IconThemeData(color: AppColors.textSecondary);
          }),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.secondary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.secondary,
          linearTrackColor: AppColors.primary,
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.secondary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.secondary,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.normal, fontSize: 14),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? AppColors.secondary : Colors.grey,
          ),
          trackColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? AppColors.primary : Colors.grey.shade300,
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected) ? AppColors.secondary : Colors.transparent,
          ),
          checkColor: WidgetStateProperty.all(Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.secondary,
        brightness: Brightness.dark,
        primary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        surface: AppColors.darkSurface,
        error: const Color(0xFFEF5350),
        onPrimary: Colors.white,
        onSurface: AppColors.darkText,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: _buildTextTheme(AppColors.darkText, AppColors.darkTextSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkSurface,
        foregroundColor: AppColors.darkText,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.darkText,
        ),
        iconTheme: const IconThemeData(color: AppColors.darkText),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: Colors.white,
          minimumSize: const Size(88, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.secondary,
          minimumSize: const Size(88, 48),
          side: const BorderSide(color: AppColors.secondary, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEF5350), width: 2),
        ),
        hintStyle: GoogleFonts.inter(color: const Color(0xFF5E6068), fontSize: 14),
        labelStyle: GoogleFonts.inter(color: AppColors.darkTextSecondary, fontSize: 14),
        floatingLabelStyle: GoogleFonts.inter(color: AppColors.secondary, fontSize: 12),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.darkDivider),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.secondary.withAlpha(38),
        selectedColor: AppColors.secondary,
        labelStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.darkText),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.secondary.withAlpha(51),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary);
          }
          return GoogleFonts.inter(fontSize: 11, color: AppColors.darkTextSecondary);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.secondary);
          }
          return const IconThemeData(color: Color(0xFF9E9E9E));
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.secondary,
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
        contentTextStyle: GoogleFonts.inter(color: AppColors.darkText),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.secondary,
        linearTrackColor: Color(0xFF2C2E35),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.secondary,
        unselectedLabelColor: AppColors.darkTextSecondary,
        indicatorColor: AppColors.secondary,
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.normal, fontSize: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.secondary : const Color(0xFF5E6068),
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.secondary.withAlpha(102)
              : const Color(0xFF2C2E35),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.secondary : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: const BorderSide(color: Color(0xFF5E6068)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: Colors.transparent,
        iconColor: AppColors.secondary,
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: primary,
        height: 1.2,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 26,
        fontWeight: FontWeight.bold,
        color: primary,
        height: 1.3,
      ),
      displaySmall: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: primary,
        height: 1.3,
      ),
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: primary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: primary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: secondary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: 0.5,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondary,
        letterSpacing: 0.3,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.normal,
        color: secondary,
      ),
    );
  }
}
