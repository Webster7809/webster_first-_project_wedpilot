import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/wed_card.dart';

class AdminCategoriesScreen extends StatelessWidget {
  const AdminCategoriesScreen({super.key});

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'venue':
        return Icons.apartment_outlined;
      case 'catering':
        return Icons.restaurant_outlined;
      case 'photography':
        return Icons.camera_alt_outlined;
      case 'decor & flowers':
        return Icons.local_florist_outlined;
      case 'dj & mc':
        return Icons.music_note;
      case 'transport':
        return Icons.directions_bus_outlined;
      case 'wedding attire':
        return Icons.checkroom_outlined;
      case 'cake & sweets':
        return Icons.cake_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  Color _backgroundForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'venue':
        return AppColors.adminBlueBg;
      case 'catering':
        return AppColors.adminAmberBg;
      case 'photography':
        return AppColors.adminIndigoBg;
      case 'decor & flowers':
        return AppColors.adminPinkBg;
      case 'dj & mc':
        return AppColors.adminGreenBg;
      case 'transport':
        return AppColors.adminBlueBg;
      case 'wedding attire':
        return AppColors.adminNeutralBg;
      case 'cake & sweets':
        return AppColors.adminAmberBg;
      default:
        return AppColors.adminNeutralBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = AppConstants.vendorCategories;

    return Scaffold(
      backgroundColor: AppColors.adminPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: AppColors.divider,
        title: Text(
          'Categories',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Service categories', style: AppTextStyles.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'These are the vendor service categories used across the app. Admins can review and maintain category definitions here as the platform evolves.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            );
          }

          final category = categories[index - 1];
          final icon = _iconForCategory(category);
          final allocation =
              AppConstants.defaultBudgetAllocation[category] ?? 0.0;

          return WedCard(
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _backgroundForCategory(category),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category, style: AppTextStyles.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Default budget allocation: ${(allocation * 100).toStringAsFixed(0)}%',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.adminIndigoBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Active',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.adminIndigo,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
