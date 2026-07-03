import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/state/resource.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/messaging.dart';
import '../../../models/vendor_profile.dart';
import '../../../providers/vendor_own_provider.dart';
import '../../../widgets/wed_button.dart';

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownState = ref.watch(vendorOwnProvider);

    if (ownState.status == ResourceStatus.initial) {
      Future.microtask(() => ref.read(vendorOwnProvider.notifier).loadOwnVendorData());
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: ownState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (message) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off_rounded,
                    size: 48, color: Theme.of(context).colorScheme.onSurface.withAlpha(102)),
                const SizedBox(height: 16),
                Text("Couldn't load your dashboard", style: AppTextStyles.headlineMedium),
                const SizedBox(height: 8),
                Text(message,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                WedButton(
                  label: 'Retry',
                  onPressed: () => ref.read(vendorOwnProvider.notifier).loadOwnVendorData(),
                  icon: Icons.refresh_rounded,
                  borderRadius: 30,
                ),
              ],
            ),
          ),
        ),
        data: (ownData) => _VendorDashboardBody(
          vendor: ownData.profile,
          inquiries: ownData.inquiries,
          services: ownData.services,
        ),
      ),
    );
  }
}

class _VendorDashboardBody extends StatelessWidget {
  final VendorProfile? vendor;
  final List<Inquiry> inquiries;
  final List<VendorService> services;

  const _VendorDashboardBody({required this.vendor, required this.inquiries, required this.services});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
          // ── Header ─────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: AppColors.forestGreen,
            expandedHeight: 140,
            elevation: 0,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 24),
                onPressed: () => context.push(AppRoutes.notifications),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.storefront_rounded,
                                color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  vendor?.businessName ?? 'My Business',
                                  style: AppTextStyles.headlineSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${vendor?.category ?? 'Venue'} · ${vendor?.location ?? 'Ndola'}',
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

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Stats row ─────────────────────────────────────────────────
                Row(
                  children: [
                    _StatCard(
                      value: vendor?.rating?.toStringAsFixed(1) ?? '—',
                      label: 'Rating',
                      icon: Icons.star_rounded,
                      iconColor: AppColors.amber,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      value: services.length.toString(),
                      label: 'Listings',
                      icon: Icons.grid_view_rounded,
                      iconColor: AppColors.forestGreen,
                    ),
                    const SizedBox(width: 10),
                    _StatCard(
                      value: inquiries.length.toString(),
                      label: 'Inquiries',
                      icon: Icons.mail_outline_rounded,
                      iconColor: AppColors.teal,
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Quick actions ─────────────────────────────────────────────
                Text('Quick actions',
                    style: AppTextStyles.headlineSmall
                        .copyWith(color: AppColors.forestGreen)),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.1,
                  children: [
                    _QuickAction(
                      icon: Icons.grid_view_rounded,
                      label: 'Listings',
                      onTap: () => context.go(AppRoutes.vendorListings),
                    ),
                    _QuickAction(
                      icon: Icons.mail_outline_rounded,
                      label: 'Inquiries',
                      onTap: () => context.go(AppRoutes.vendorLeads),
                    ),
                    _QuickAction(
                      icon: Icons.star_outline_rounded,
                      label: 'Reviews',
                      onTap: () => context.go(AppRoutes.vendorReviews),
                    ),
                    _QuickAction(
                      icon: Icons.calendar_month_outlined,
                      label: 'Calendar',
                      onTap: () => context.push(AppRoutes.vendorAvailability),
                    ),
                    _QuickAction(
                      icon: Icons.bar_chart_rounded,
                      label: 'Analytics',
                      onTap: () => context.push(AppRoutes.vendorAnalytics),
                    ),
                    _QuickAction(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Upgrade',
                      onTap: () => context.push(AppRoutes.vendorSubscription),
                    ),
                    _QuickAction(
                      icon: Icons.edit_note_rounded,
                      label: 'Update listing',
                      onTap: () => context.push(AppRoutes.vendorOnboarding),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Listing summary ───────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Listing',
                        style: AppTextStyles.headlineSmall
                            .copyWith(color: AppColors.forestGreen)),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.vendorListings),
                      child: Text('Edit',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.amber)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
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
                      _InfoRow(
                        icon: Icons.storefront_outlined,
                        label: 'Business name',
                        value: vendor?.businessName ?? 'Not set',
                      ),
                      const Divider(height: 1, indent: 52),
                      _InfoRow(
                        icon: Icons.category_outlined,
                        label: 'Category',
                        value: vendor?.category ?? 'Not set',
                      ),
                      const Divider(height: 1, indent: 52),
                      _InfoRow(
                        icon: Icons.credit_card_outlined,
                        label: 'Price range',
                        value: services.isNotEmpty
                            ? 'ZMW ${services.map((s) => s.priceMin).reduce((a, b) => a < b ? a : b).toStringAsFixed(0)} – ${services.map((s) => s.priceMax).reduce((a, b) => a > b ? a : b).toStringAsFixed(0)}'
                            : 'Not set',
                      ),
                      const Divider(height: 1, indent: 52),
                      _InfoRow(
                        icon: Icons.location_on_outlined,
                        label: 'Location',
                        value: vendor?.location ?? 'Not set',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // ── Recent inquiries preview ───────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recent inquiries',
                        style: AppTextStyles.headlineSmall
                            .copyWith(color: AppColors.forestGreen)),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.vendorLeads),
                      child: Text('See all',
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.amber)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (inquiries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No inquiries yet.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  )
                else
                  ...inquiries.take(2).map((inq) => _InquiryCard(inquiry: inq)),
              ]),
            ),
          ),
        ],
      );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.forestGreen.withAlpha(15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.forestGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick action tile ─────────────────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.forestGreen.withAlpha(12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: AppColors.forestGreen),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.amber),
          const SizedBox(width: 14),
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
        ],
      ),
    );
  }
}

// ── Inquiry preview card ──────────────────────────────────────────────────────

class _InquiryCard extends StatelessWidget {
  final Inquiry inquiry;

  const _InquiryCard({required this.inquiry});

  @override
  Widget build(BuildContext context) {
    final dateLabel = inquiry.weddingDate != null
        ? DateFormat('MMM d').format(inquiry.weddingDate!)
        : DateFormat('MMM d').format(inquiry.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: AppColors.forestGreen.withAlpha(18),
          child: const Icon(Icons.people_outline_rounded,
              size: 20, color: AppColors.forestGreen),
        ),
        title: Text(inquiry.coupleName ?? 'Unknown couple',
            style: AppTextStyles.bodySmall
                .copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(inquiry.message,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        trailing: Text(dateLabel,
            style:
                AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        onTap: () => context.go(AppRoutes.vendorLeads),
      ),
    );
  }
}
