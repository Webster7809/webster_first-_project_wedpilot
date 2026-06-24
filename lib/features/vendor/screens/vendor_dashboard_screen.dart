import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendor = ref.watch(vendorProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // ── Dark green header ───────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: AppColors.forestGreen,
            expandedHeight: 160,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 24),
                onPressed: () => context.push('/notifications'),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'VENDOR DASHBOARD',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.amber,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.amber,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.storefront_rounded,
                                color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vendor?.businessName ?? 'Mukuba Gardens',
                                  style: AppTextStyles.headlineMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${vendor?.category ?? 'Venue'} · ${vendor?.location ?? 'Ndola, Copperbelt'}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white.withAlpha(178),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildListDelegate([
              // ── Stats cards — overlap the header ──────────────────────────
              Transform.translate(
                offset: const Offset(0, -28),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: vendor?.rating?.toStringAsFixed(1) ?? '4.9',
                          label: 'AVG RATING',
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: _StatCard(value: '38', label: 'INQUIRIES'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          value:
                              '${vendor?.compositeScore.round() ?? 96}%',
                          label: 'MATCH\nSCORE',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Portfolio gallery ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Portfolio gallery',
                        style: AppTextStyles.headlineSmall
                            .copyWith(color: AppColors.forestGreen)),
                    GestureDetector(
                      onTap: () {},
                      child: Text('+ Add photo',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.amber)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.0,
                  children: [
                    ...List.generate(5, (i) => _PhotoCell(isEmpty: false)),
                    _PhotoCell(isEmpty: true),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Listing details ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('Listing details',
                    style: AppTextStyles.headlineSmall
                        .copyWith(color: AppColors.forestGreen)),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.forestGreen.withAlpha(12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _ListingField(
                        icon: Icons.edit_outlined,
                        label: 'Listing name',
                        value: vendor?.businessName != null
                            ? '${vendor!.businessName} — Open Air Venue'
                            : 'Mukuba Gardens — Open Air Venue',
                        onTap: () => context.push('/vendor/account'),
                      ),
                      const Divider(height: 1, indent: 52),
                      _ListingField(
                        icon: Icons.credit_card_outlined,
                        label: 'Price range',
                        value: vendor != null && vendor.services.isNotEmpty
                            ? 'ZMW ${vendor.priceMin.toStringAsFixed(0)} – ${vendor.priceMax.toStringAsFixed(0)} per event'
                            : 'ZMW 28,000 – 35,000 per event',
                        onTap: () => context.push('/vendor/account'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.forestGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Portfolio photo cell ───────────────────────────────────────────────────────

class _PhotoCell extends StatelessWidget {
  final bool isEmpty;
  const _PhotoCell({required this.isEmpty});

  @override
  Widget build(BuildContext context) {
    if (isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.divider,
            style: BorderStyle.solid,
          ),
        ),
        child: const Icon(Icons.upload_outlined,
            color: AppColors.textHint, size: 22),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.photo_camera_outlined,
          color: AppColors.amber.withAlpha(153), size: 22),
    );
  }
}

// ── Listing detail field ───────────────────────────────────────────────────────

class _ListingField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ListingField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.forestGreen)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 16, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}

