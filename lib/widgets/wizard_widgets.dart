import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'dash_progress_bar.dart';

/// Green header used at the top of multi-step onboarding wizards.
class WizardHeader extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String stepLabel;
  final String stepTitle;
  final VoidCallback? onBack;

  const WizardHeader({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.stepLabel,
    required this.stepTitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.forestGreen,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (onBack != null)
                    Material(
                      color: Colors.white.withAlpha(30),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onBack,
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(Icons.chevron_left_rounded,
                              color: Colors.white, size: 22),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'STEP ${step + 1} OF $totalSteps',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                stepLabel,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.amber,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                stepTitle,
                style: const TextStyle(
                  fontFamily: 'Playfair Display',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 16),
              DashProgressBar(total: totalSteps, current: step),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon + label row used as form section headings inside wizard steps.
class WizardSectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? suffix;

  const WizardSectionLabel({
    super.key,
    required this.icon,
    required this.label,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.amber),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (suffix != null) ...[
          const SizedBox(width: 6),
          Text(
            suffix!,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

/// Full-width continue/submit button for wizard steps.
/// Set [showArrow] to true to append a forward-arrow icon (vendor flow).
class WizardContinueButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool showArrow;
  final bool isLoading;

  const WizardContinueButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.showArrow = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            if (showArrow) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, size: 16),
            ],
          ],
        ),
      ),
    );
  }
}
