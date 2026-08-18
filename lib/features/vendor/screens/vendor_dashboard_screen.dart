import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/state/resource.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/logout_dialog.dart';
import '../../../models/messaging.dart';
import '../../../models/vendor_profile.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/vendor_own_provider.dart';
import '../../../widgets/action_menu.dart';
import '../../../widgets/hamburger_menu_button.dart';
import '../../../widgets/wed_error_state.dart';
import '../../../widgets/wed_skeleton.dart';

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownState = ref.watch(vendorOwnProvider);

    if (ownState.status == ResourceStatus.initial) {
      Future.microtask(
          () => ref.read(vendorOwnProvider.notifier).loadOwnVendorData());
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ownState.when(
        loading: () =>
            const WedListSkeleton(rows: 4, asCards: true, cardHeight: 110),
        error: (message) => WedErrorState(
          title: "Couldn't load your dashboard",
          message: message,
          icon: Icons.cloud_off,
          retryLabel: 'Retry',
          onRetry: () =>
              ref.read(vendorOwnProvider.notifier).loadOwnVendorData(),
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

class _VendorDashboardBody extends ConsumerStatefulWidget {
  final VendorProfile? vendor;
  final List<Inquiry> inquiries;
  final List<VendorService> services;

  const _VendorDashboardBody({
    required this.vendor,
    required this.inquiries,
    required this.services,
  });

  @override
  ConsumerState<_VendorDashboardBody> createState() =>
      _VendorDashboardBodyState();
}

class _VendorDashboardBodyState extends ConsumerState<_VendorDashboardBody> {
  /// Quick actions start open so the dashboard still leads with something to
  /// do — collapsing is for getting them out of the way, not for hiding them
  /// behind a tap on first arrival.
  bool _actionsOpen = true;

  String get _businessName => widget.vendor?.businessName ?? 'My Business';

  /// Inquiries received in the last seven days — the header stat.
  int get _inquiriesThisWeek {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return widget.inquiries.where((i) => i.createdAt.isAfter(cutoff)).length;
  }

  int get _newInquiries => widget.inquiries
      .where((i) => i.status == InquiryStatus.newInquiry)
      .length;

  /// Confirmed bookings whose wedding day is today.
  int get _bookingsToday {
    final now = DateTime.now();
    return widget.inquiries.where((i) {
      final d = i.weddingDate;
      return i.status == InquiryStatus.booked &&
          d != null &&
          d.year == now.year &&
          d.month == now.month &&
          d.day == now.day;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final unread = ref
            .watch(notificationsProvider)
            .valueOrNull
            ?.where((n) => !n.isRead)
            .length ??
        0;

    // Centres the stats, action grid and listing banner on a wide window.
    final gutter =
        AppDimensions.gutter(MediaQuery.sizeOf(context).width, minGutter: 16);

    // vendorOwnProvider loads once and never refetches, so a rating a
    // couple left after the app opened never appeared — the vendor's own
    // score looked frozen even though the backend had already recomputed
    // it. Pull-to-refresh is the fix that also covers new leads and
    // bookings arriving while the dashboard is open.
    return RefreshIndicator(
      color: AppColors.forestGreen,
      onRefresh: () =>
          ref.read(vendorOwnProvider.notifier).loadOwnVendorData(),
      child: CustomScrollView(
        // Always scrollable so the pull gesture works even when the
        // content is shorter than the screen.
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Same shape and chrome as the couple dashboard's header: a
          // floating SliverAppBar with the hamburger, a two-line welcome
          // title, and direct notification/logout actions — rather than a
          // bespoke banner with its own avatar and dropdown. "My listing",
          // "Account settings" and "Help and support" already live in
          // VendorDrawer (behind the same hamburger), so that dropdown was
          // pure duplication, not a second way to reach anything new.
          SliverAppBar(
            pinned: false,
            floating: true,
            snap: true,
            backgroundColor: AppColors.forestGreen,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            leading: const HamburgerMenuButton(color: Colors.white),
            toolbarHeight: 68,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome back',
                  style: AppTextStyles.caption.copyWith(
                    // Gold on the forest header — 4.99:1.
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                Text(
                  _businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            actions: [
              _NotificationBell(unreadCount: unread),
              IconButton(
                tooltip: 'Log out',
                icon: const Icon(Icons.logout, color: Colors.white, size: 26),
                onPressed: () => confirmLogout(context, ref),
              ),
              const SizedBox(width: 4),
            ],
          ),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(gutter, 20, gutter, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        value: '$_inquiriesThisWeek',
                        label: 'Inquiries this week',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        value:
                            widget.vendor?.rating?.toStringAsFixed(1) ?? '—',
                        label: 'Average rating',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Quick actions',
                  style: AppTextStyles.headlineLarge
                      .copyWith(color: AppColors.forestGreen),
                ),
                const SizedBox(height: 2),
                Text(
                  'Manage your business',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                ActionMenu(
                  noun: 'actions',
                  icon: Icons.bolt_outlined,
                  expanded: _actionsOpen,
                  onToggle: () =>
                      setState(() => _actionsOpen = !_actionsOpen),
                  items: [
                    ActionMenuItem(
                      icon: Icons.grid_view_rounded,
                      label: 'Listings',
                      trailing: '${widget.services.length} active',
                      onTap: () => context.go(AppRoutes.vendorListings),
                    ),
                    ActionMenuItem(
                      icon: Icons.mail_outline,
                      label: 'Inquiries',
                      trailing: '${widget.inquiries.length} total',
                      badge: _newInquiries > 0 ? '$_newInquiries new' : null,
                      onTap: () => context.go(AppRoutes.vendorLeads),
                    ),
                    ActionMenuItem(
                      icon: Icons.star_outline,
                      label: 'Feedback',
                      trailing: widget.vendor?.rating != null
                          ? '${widget.vendor!.rating!.toStringAsFixed(1)} avg'
                          : 'No ratings yet',
                      // push, not go: /vendor/feedback lives outside the
                      // shell (see app_router.dart), so go() replaced this
                      // as the current location with nothing left to pop
                      // back to — the screen's SliverAppBar never got an
                      // automatic back button. push puts it on the stack
                      // properly, same as Calendar/Analytics/Upgrade below.
                      onTap: () => context.push(AppRoutes.vendorFeedback),
                    ),
                    ActionMenuItem(
                      icon: Icons.calendar_today_outlined,
                      label: 'Calendar',
                      trailing: '$_bookingsToday today',
                      onTap: () => context.push(AppRoutes.vendorAvailability),
                    ),
                    ActionMenuItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'Analytics',
                      // Profile views aren't tracked anywhere yet (see the
                      // analytics screen), so this shows a number the app
                      // actually holds rather than inventing one.
                      trailing: '${widget.inquiries.length} leads',
                      onTap: () => context.push(AppRoutes.vendorAnalytics),
                    ),
                    ActionMenuItem(
                      icon: Icons.workspace_premium_outlined,
                      label: 'Upgrade',
                      trailing: 'Go Pro',
                      promo: true,
                      onTap: () =>
                          context.push(AppRoutes.vendorSubscription),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _ListingBanner(
                  businessName: _businessName,
                  category: widget.vendor?.category,
                  location: widget.vendor?.location,
                  onEdit: () => context.go(AppRoutes.vendorListings),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int unreadCount;

  const _NotificationBell({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(Icons.notifications_outlined,
              color: Colors.white, size: 24),
          onPressed: () => context.push(AppRoutes.notifications),
        ),
        if (unreadCount > 0)
          Positioned(
            top: 8,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16),
              decoration: BoxDecoration(
                color: AppColors.gold,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textOnSecondary,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Cards ─────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.figure.copyWith(color: AppColors.forestGreen),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ListingBanner extends StatelessWidget {
  final String businessName;
  final String? category;
  final String? location;
  final VoidCallback onEdit;

  const _ListingBanner({
    required this.businessName,
    required this.category,
    required this.location,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = [category, location].whereType<String>().join(' · ');

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onEdit,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.iconTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront_outlined,
                      size: 22, color: AppColors.forestGreen),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        businessName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headlineLarge.copyWith(
                          color: AppColors.forestGreen,
                          fontSize: 20,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // goldDeep, not gold: a gold glyph on white is 2.12:1.
                const Icon(Icons.edit_outlined,
                    color: AppColors.goldDeep, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

