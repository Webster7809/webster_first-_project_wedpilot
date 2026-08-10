import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// A small gold pill reporting a rating/match score — the compact counterpart
/// to the inline star+number pattern used elsewhere. Caller formats the score
/// (e.g. "4.8") so this widget stays purely presentational.
class WedScoreBadge extends StatelessWidget {
  final String score;

  const WedScoreBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 12, color: AppColors.goldDeep),
          const SizedBox(width: 4),
          Text(
            score,
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
