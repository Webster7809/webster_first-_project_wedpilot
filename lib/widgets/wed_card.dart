import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/vendor_profile.dart';

class WedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double borderRadius;

  const WedCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: AppColors.cardShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

class VendorCard extends StatelessWidget {
  final VendorProfile vendor;
  final bool isWishlisted;
  final bool isPicked;
  final VoidCallback onTap;
  final VoidCallback onWishlistToggle;
  final int? rank;

  const VendorCard({
    super.key,
    required this.vendor,
    required this.isWishlisted,
    required this.onTap,
    required this.onWishlistToggle,
    this.rank,
    this.isPicked = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shadowColor: AppColors.cardShadow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 140,
                  width: double.infinity,
                  color: AppColors.primary.withAlpha(77),
                  child: const Center(
                    child: Icon(Icons.photo_camera, size: 40, color: AppColors.accent),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onWishlistToggle,
                    child: Builder(
                      builder: (ctx) => Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(ctx).colorScheme.surface.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isWishlisted ? Icons.favorite : Icons.favorite_border,
                          color: isWishlisted
                              ? AppColors.secondary
                              : Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.6),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                if (rank != null && rank! <= 3)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.goldPremium,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 12, color: Colors.white),
                          const SizedBox(width: 3),
                          Text('AI Pick',
                              style: AppTextStyles.caption
                                  .copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                if (vendor.tier == VendorTier.premium)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.roseGoldPremium,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('PREMIUM',
                          style: AppTextStyles.caption
                              .copyWith(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 9)),
                    ),
                  ),
                if (isPicked)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, size: 11, color: Colors.white),
                          const SizedBox(width: 3),
                          Text('Picked',
                              style: AppTextStyles.caption.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(vendor.businessName,
                            style: AppTextStyles.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (vendor.isVerified)
                        const Icon(Icons.verified, color: AppColors.info, size: 16),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 12,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(vendor.location ?? '',
                            style: AppTextStyles.caption.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 13, color: AppColors.goldPremium),
                      const SizedBox(width: 2),
                      Text(
                        vendor.rating?.toStringAsFixed(1) ?? '—',
                        style: AppTextStyles.labelMedium,
                      ),
                      Text(' (${vendor.reviewCount})',
                          style: AppTextStyles.caption.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          )),
                      const Spacer(),
                      if (vendor.services.isNotEmpty)
                        Text(
                          'From \$${vendor.priceMin.toStringAsFixed(0)}',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.secondary, fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BudgetCategoryCard extends StatelessWidget {
  final String categoryName;
  final String categoryIcon;
  final double allocated;
  final double spent;
  final String currency;
  final VoidCallback? onTap;

  const BudgetCategoryCard({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.allocated,
    required this.spent,
    required this.currency,
    this.onTap,
  });

  double get percent => allocated > 0 ? (spent / allocated).clamp(0, 1) : 0;

  Color get barColor {
    if (percent >= 1.0) return AppColors.budgetRed;
    if (percent >= 0.9) return AppColors.budgetAmber;
    return AppColors.budgetGreen;
  }

  @override
  Widget build(BuildContext context) {
    return WedCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(categoryIcon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(categoryName, style: AppTextStyles.titleMedium),
              ),
              if (percent >= 0.9)
                Icon(
                  percent >= 1.0 ? Icons.warning_rounded : Icons.info_outline,
                  size: 16,
                  color: percent >= 1.0 ? AppColors.budgetRed : AppColors.budgetAmber,
                ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('\$$currency ${spent.toStringAsFixed(0)} spent',
                  style: AppTextStyles.caption),
              Text('of \$$currency ${allocated.toStringAsFixed(0)}',
                  style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }
}
