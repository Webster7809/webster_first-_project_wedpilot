import 'package:flutter/material.dart';
import '../core/inherited/shell_scaffold.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import 'dash_progress_bar.dart';
import 'onboarding_photo_background.dart';

/// Header used at the top of multi-step onboarding wizards, backed by a
/// slow-cross-fading photo slideshow ([backgroundAssets]) with a dark scrim
/// so the step copy stays legible over any photo.
class WizardHeader extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String stepLabel;
  final String stepTitle;
  final List<String> backgroundAssets;
  final VoidCallback? onBack;

  const WizardHeader({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.stepLabel,
    required this.stepTitle,
    required this.backgroundAssets,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: OnboardingPhotoBackground(assetPaths: backgroundAssets),
        ),
        SafeArea(
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
                            child: Icon(Icons.chevron_left,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      )
                    else
                      Builder(builder: (context) {
                        // Only the couple shell's Budget tab renders this inside
                        // a ShellScaffold — the same wizard header used for
                        // standalone onboarding (couple + vendor) has no drawer
                        // to open, so it keeps the plain spacer there.
                        final shell = ShellScaffold.of(context);
                        if (shell == null) return const SizedBox(width: 36);
                        return Material(
                          color: Colors.white.withAlpha(30),
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () =>
                                shell.scaffoldKey.currentState?.openDrawer(),
                            child: const SizedBox(
                              width: 36,
                              height: 36,
                              child:
                                  Icon(Icons.menu, color: Colors.white, size: 22),
                            ),
                          ),
                        );
                      }),
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
                    // Gold, not white: this header now sits over a photo, and
                    // gold is what separates the eyebrow from the step title
                    // below it rather than the two reading as one block.
                    color: AppColors.gold,
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
      ],
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
        Icon(icon, size: 18, color: AppColors.goldDeep),
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

