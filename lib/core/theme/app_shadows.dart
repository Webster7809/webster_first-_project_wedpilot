import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppShadows {
  static List<BoxShadow> get xs => [
        BoxShadow(
          color: AppColors.forestGreen.withAlpha(10),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get sm => [
        BoxShadow(
          color: AppColors.forestGreen.withAlpha(14),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get md => [
        BoxShadow(
          color: AppColors.forestGreen.withAlpha(18),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get lg => [
        BoxShadow(
          color: AppColors.forestGreen.withAlpha(22),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get xl => [
        BoxShadow(
          color: AppColors.forestGreen.withAlpha(28),
          blurRadius: 32,
          offset: const Offset(0, 10),
        ),
      ];

  // Card shadow — standard white card over cream background
  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.forestGreen.withAlpha(14),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ];

  // Elevated card (e.g. stat cards, modal cards)
  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: AppColors.forestGreen.withAlpha(20),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  // Header / AppBar drop shadow
  static List<BoxShadow> get header => [
        BoxShadow(
          color: Colors.black.withAlpha(20),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  // Ambient shadow for overlapping elements
  static List<BoxShadow> get ambient => [
        BoxShadow(
          color: Colors.black.withAlpha(10),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
      ];
}
