import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/format_utils.dart';
import '../providers/invitation_provider.dart';

/// Guest-based catering estimate, shown on both the RSVP dashboard's
/// Overview tab and the Budget screen — never mutates [Budget], purely a
/// read-only insight derived from live RSVP + vendor data (see
/// [cateringEstimateProvider]). Dismissible for the current session only;
/// it reappears next time the couple opens the screen, since the number
/// itself may have moved on by then.
class CateringEstimateCard extends ConsumerStatefulWidget {
  const CateringEstimateCard({super.key});

  @override
  ConsumerState<CateringEstimateCard> createState() => _CateringEstimateCardState();
}

class _CateringEstimateCardState extends ConsumerState<CateringEstimateCard> {
  bool _dismissed = false;

  String _priceText(double min, double max) =>
      min == max ? fmtCurrency(min) : '${fmtCurrency(min)}–${fmtCurrency(max)}';

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    final estimate = ref.watch(cateringEstimateProvider);
    if (estimate == null) return const SizedBox.shrink();
    if (estimate.status == CateringEstimateStatus.available && estimate.confirmedGuests <= 0) {
      return const SizedBox.shrink();
    }

    final String message;
    switch (estimate.status) {
      case CateringEstimateStatus.available:
        message = 'With ${estimate.confirmedGuests} confirmed, catering is now estimated at '
            '${fmtCurrency(estimate.estimatedTotal!)} (${estimate.vendorName} priced at '
            '${_priceText(estimate.priceMin!, estimate.priceMax!)}/person). Your budget itself is unchanged.';
      case CateringEstimateStatus.cannotCalculate:
        message = estimate.vendorName != null
            ? '${estimate.vendorName} doesn\'t have a single active per-person price yet, '
                'so a guest-based catering estimate can\'t be calculated automatically.'
            : 'You have more than one booked caterer, so a guest-based catering estimate '
                'can\'t be calculated automatically.';
      case CateringEstimateStatus.noBookedCaterer:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.amber.withAlpha(23),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.amber.withAlpha(90)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.insights_outlined, color: AppColors.goldDeep, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Guest-Based Estimate', style: AppTextStyles.labelLarge),
                const SizedBox(height: 4),
                Text(message, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          InkWell(
            onTap: () => setState(() => _dismissed = true),
            borderRadius: BorderRadius.circular(12),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 16, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
