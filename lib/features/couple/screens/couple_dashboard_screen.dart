import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/services/vendor_api_service.dart' show resolveMediaUrl;
import '../../../core/state/resource.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/invitation_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/vendor_provider.dart';

class CoupleDashboardScreen extends ConsumerWidget {
  const CoupleDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couple = ref.watch(coupleProfileProvider);
    final budgetState = ref.watch(budgetProvider);
    final budget = budgetState.data;
    final user = ref.watch(currentUserProvider);
    final tasksState = ref.watch(taskProvider);
    final tasks = tasksState.data ?? [];

    if (couple?.hasBudget == true &&
        budgetState.status == ResourceStatus.initial) {
      Future.microtask(
        () => ref
            .read(budgetProvider.notifier)
            .initializeBudgetForProfile(couple),
      );
    }
    if (tasksState.status == ResourceStatus.initial) {
      Future.microtask(() => ref.read(taskProvider.notifier).loadTasks());
    }
    if (ref.read(wishlistProvider.notifier).status == ResourceStatus.initial) {
      Future.microtask(
        () => ref.read(wishlistProvider.notifier).loadWishlist(),
      );
    }

    final shortlisted = ref.watch(wishlistedVendorsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: false,
            floating: true,
            snap: true,
            backgroundColor: AppColors.cream,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            toolbarHeight: 68,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Welcome back',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  _coupleDisplayName(user?.name, couple?.partnerName),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.forestGreen,
                  ),
                ),
              ],
            ),
            actions: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.forestGreen,
                      size: 26,
                    ),
                    onPressed: () => context.push('/notifications'),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: AppColors.amber,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.forestGreen,
                  size: 26,
                ),
                onPressed: () => _confirmLogout(context, ref),
              ),
              const SizedBox(width: 4),
            ],
          ),

          // ── Responsive Content ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 48),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isTablet = screenWidth >= AppDimensions.tabletMin;
                  final isDesktop = screenWidth >= AppDimensions.desktopMin;

                  final content = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Stat cards (responsive grid) ─────────────────────────
                      _StatCardsGrid(
                        couple: couple,
                        budget: budget,
                        isTablet: isTablet,
                        onBudgetDetails: () => context.go('/couple/budget'),
                        onBudgetSetup: () => context.push('/couple/plan-setup'),
                        onGuestsSetup: () =>
                            context.push('/couple/invitations'),
                      ),
                      const SizedBox(height: 24),

                      // ── Shortlist ─────────────────────────────────────────────
                      _SectionRow(
                        title: 'Your shortlist',
                        actionLabel: 'See all',
                        onAction: () => context.push('/couple/wishlist'),
                      ),
                      const SizedBox(height: 12),
                      _ShortlistScroll(
                        vendors: shortlisted,
                        onTap: (id) => context.push('/couple/vendors/$id'),
                        onDiscover: () => context.go('/couple/vendors'),
                      ),
                      const SizedBox(height: 28),

                      // ── Planning Checklist ────────────────────────────────────
                      _SectionRow(
                        title: 'Planning checklist',
                        actionLabel: 'View all',
                        onAction: () => context.push('/couple/checklist'),
                      ),
                      const SizedBox(height: 12),
                      _ChecklistPreview(
                        tasks: tasks.take(3).toList(),
                        onTap: () => context.push('/couple/checklist'),
                      ),
                    ],
                  );

                  if (isDesktop) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppDimensions.contentMaxWidth,
                        ),
                        child: content,
                      ),
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24.0 : 16.0,
                    ),
                    child: content,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _coupleDisplayName(String? name1, String? name2) {
  if (name1 == null) return 'Your Wedding';
  if (name2 == null || name2.isEmpty) return name1;
  return '$name1 & $name2';
}

void _confirmLogout(BuildContext context, WidgetRef ref) {
  showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Log Out'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            ref.read(authProvider.notifier).logout();
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Log Out'),
        ),
      ],
    ),
  );
}

// ── Responsive stat card grid ──────────────────────────────────────────────────

class _StatCardsGrid extends ConsumerWidget {
  final dynamic couple;
  final dynamic budget;
  final bool isTablet;
  final VoidCallback onBudgetDetails;
  final VoidCallback onBudgetSetup;
  final VoidCallback onGuestsSetup;

  const _StatCardsGrid({
    required this.couple,
    this.budget,
    required this.isTablet,
    required this.onBudgetDetails,
    required this.onBudgetSetup,
    required this.onGuestsSetup,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rsvpStats = ref.watch(rsvpStatsProvider);
    if (ref.read(guestRsvpProvider.notifier).status == ResourceStatus.initial) {
      Future.microtask(() => ref.read(guestRsvpProvider.notifier).load());
    }
    final countdown = _CountdownCard(
      couple: couple,
      onSetDate: () => context.push('/couple/plan-setup'),
    );
    final budgetCard = budget != null
        ? _BudgetOverviewCard(budget: budget, onDetails: onBudgetDetails)
        : _SetupBudgetPrompt(onTap: onBudgetSetup);
    final rsvp = _RsvpCard(
      confirmed: rsvpStats.attending,
      total: rsvpStats.totalInvited,
      onSetupGuests: onGuestsSetup,
    );

    if (isTablet) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          countdown,
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: budgetCard),
                const SizedBox(width: 12),
                Expanded(child: rsvp),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        countdown,
        const SizedBox(height: 12),
        budgetCard,
        const SizedBox(height: 12),
        rsvp,
      ],
    );
  }
}

// ── Section row header ─────────────────────────────────────────────────────────

class _SectionRow extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionRow({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.forestGreen,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.amber,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Wedding Countdown Card ─────────────────────────────────────────────────────

class _CountdownCard extends StatelessWidget {
  final dynamic couple;
  final VoidCallback onSetDate;
  const _CountdownCard({this.couple, required this.onSetDate});

  String _formatDate(DateTime d) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final hasDate = couple?.hasWeddingDate == true;

    if (!hasDate) {
      return GestureDetector(
        onTap: onSetDate,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.forestGreen,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.forestGreen.withAlpha(60),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.amber.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set your wedding date',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'See your countdown once it\'s set',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.amber),
            ],
          ),
        ),
      );
    }

    final days = '${couple!.daysUntilWedding}';
    final dateLabel = _formatDate(couple!.weddingDate as DateTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.forestGreen,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR WEDDING DAY',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.amber,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                days,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.amber,
                  height: 1.0,
                ),
              ),
              Text(
                'DAYS LEFT',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.amber,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Budget Overview Card ───────────────────────────────────────────────────────

class _BudgetOverviewCard extends StatelessWidget {
  final dynamic budget;
  final VoidCallback onDetails;

  const _BudgetOverviewCard({required this.budget, required this.onDetails});

  static const _catColors = AppColors.budgetCategoryColors;

  @override
  Widget build(BuildContext context) {
    final total = budget.totalAmount as double;
    final spent = budget.totalSpent as double;
    final categories =
        (budget.categories as List<dynamic>)
            .where((c) => (c.spentAmount as double) > 0)
            .toList()
          ..sort(
            (a, b) =>
                (b.spentAmount as double).compareTo(a.spentAmount as double),
          );

    final unallocated = (total - spent).clamp(0.0, total);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.elevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Budget overview',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.forestGreen,
                ),
              ),
              GestureDetector(
                onTap: onDetails,
                child: Text(
                  'Details',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'ZMW ${spent.toStringAsFixed(0)} ',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.forestGreen,
                  ),
                ),
                TextSpan(
                  text: 'spent of ZMW ${total.toStringAsFixed(0)}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SegmentedBar(
            segments: [
              ...categories
                  .take(4)
                  .map(
                    (c) => _BarSegment(
                      fraction: total > 0
                          ? (c.spentAmount as double) / total
                          : 0,
                      color:
                          _catColors[c.categoryName] ?? AppColors.forestGreen,
                    ),
                  ),
              if (unallocated > 0 && total > 0)
                _BarSegment(
                  fraction: unallocated / total,
                  color: AppColors.segmentedBarTrack,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              ...categories
                  .take(4)
                  .map(
                    (c) => _LegendDot(
                      label: c.categoryName as String,
                      color:
                          _catColors[c.categoryName] ?? AppColors.forestGreen,
                    ),
                  ),
              const _LegendDot(label: 'Unallocated', color: Color(0xFFE0DDD6)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarSegment {
  final double fraction;
  final Color color;
  const _BarSegment({required this.fraction, required this.color});
}

class _SegmentedBar extends StatelessWidget {
  final List<_BarSegment> segments;
  const _SegmentedBar({required this.segments});

  @override
  Widget build(BuildContext context) {
    if (segments.isEmpty) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: AppColors.segmentedBarTrack,
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Row(
        children: segments.map((seg) {
          return Flexible(
            flex: (seg.fraction * 1000).round().clamp(1, 1000),
            child: Container(height: 8, color: seg.color),
          );
        }).toList(),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;
  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── Budget setup prompt ────────────────────────────────────────────────────────

class _SetupBudgetPrompt extends StatelessWidget {
  final VoidCallback onTap;
  const _SetupBudgetPrompt({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.amber.withAlpha(80)),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.amber.withAlpha(26),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.amber,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set up your budget',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Let AI allocate across all categories',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.amber),
          ],
        ),
      ),
    );
  }
}

// ── RSVP Card ──────────────────────────────────────────────────────────────────

class _RsvpCard extends StatelessWidget {
  final int confirmed;
  final int total;
  final VoidCallback onSetupGuests;
  const _RsvpCard({
    required this.confirmed,
    required this.total,
    required this.onSetupGuests,
  });

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return GestureDetector(
        onTap: onSetupGuests,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.amber.withAlpha(80)),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.amber.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.people_alt_outlined,
                  color: AppColors.amber,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add your guest list',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Track RSVPs once you invite guests',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.elevated,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 16,
                    startDegreeOffset: -90,
                    sections: [
                      PieChartSectionData(
                        value: confirmed.toDouble(),
                        color: AppColors.forestGreen,
                        radius: 11,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: (total - confirmed).toDouble(),
                        color: AppColors.segmentedBarTrack,
                        radius: 11,
                        showTitle: false,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${((confirmed / total) * 100).round()}%',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    color: AppColors.forestGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$confirmed of $total confirmed',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.forestGreen,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Guests have RSVP'd to your invitation",
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shortlist Horizontal Scroll ────────────────────────────────────────────────

class _ShortlistScroll extends StatelessWidget {
  final List<dynamic> vendors;
  final void Function(String id) onTap;
  final VoidCallback onDiscover;

  const _ShortlistScroll({
    required this.vendors,
    required this.onTap,
    required this.onDiscover,
  });

  @override
  Widget build(BuildContext context) {
    if (vendors.isEmpty) {
      return GestureDetector(
        onTap: onDiscover,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.favorite_border,
                color: AppColors.amber,
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                'Add vendors to your shortlist',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: vendors.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final v = vendors[i];
          return _ShortlistCard(vendor: v, onTap: () => onTap(v.id as String));
        },
      ),
    );
  }
}

class _ShortlistCard extends StatelessWidget {
  final dynamic vendor;
  final VoidCallback onTap;

  const _ShortlistCard({required this.vendor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.sm,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 88,
              color: AppColors.cream,
              child: vendor.logoUrl != null
                  ? Image.network(
                      resolveMediaUrl(vendor.logoUrl as String),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: Icon(
                        Icons.photo_camera_outlined,
                        color: AppColors.amber.withAlpha(153),
                        size: 28,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vendor.businessName as String,
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.forestGreen,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    vendor.category as String,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

// ── Checklist Preview ──────────────────────────────────────────────────────────

class _ChecklistPreview extends StatelessWidget {
  final List<dynamic> tasks;
  final VoidCallback onTap;

  const _ChecklistPreview({required this.tasks, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          children: [
            ...tasks.map((t) => _ChecklistRow(task: t)),
            if (tasks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No tasks yet — tap to set up your checklist',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistRow extends StatelessWidget {
  final dynamic task;
  const _ChecklistRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final done = task.isCompleted as bool;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: done ? AppColors.forestGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: done ? AppColors.forestGreen : AppColors.divider,
                width: 1.5,
              ),
            ),
            child: done
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.task as String,
              style: AppTextStyles.bodySmall.copyWith(
                color: done ? AppColors.textSecondary : AppColors.textPrimary,
                decoration: done
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
