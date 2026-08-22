import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

/// Compact -/value/+ stepper used for every guest-count-style numeric input
/// (RSVP party size, a guest's max party size, etc) — kept as one shared
/// widget so all of them look and behave identically.
class CountStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final bool hasError;

  const CountStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 20,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Decrease',
          onPressed: () => onChanged((value - 1).clamp(min, max)),
          icon: const Icon(Icons.remove_circle_outlined),
          color: AppColors.goldDeep,
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: hasError ? AppColors.error : AppColors.divider,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppTextStyles.headlineSmall,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Increase',
          onPressed: () => onChanged((value + 1).clamp(min, max)),
          icon: const Icon(Icons.add_circle_outlined),
          color: AppColors.goldDeep,
        ),
      ],
    );
  }
}
