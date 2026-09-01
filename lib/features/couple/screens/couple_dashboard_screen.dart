import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/constants/vendor_category_images.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/state/resource.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../models/vendor_profile.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/budget_provider.dart';
import '../../../providers/invitation_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/task_provider.dart';
import '../../../providers/vendor_provider.dart';
import '../../../widgets/action_menu.dart';
import '../../../widgets/hamburger_menu_button.dart';
import '../../../widgets/rate_vendor_prompt.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/vendor_hero_image.dart';

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

    // Pops up automatically once a booking is marked complete — once per
    // vendor per app session, so it doesn't nag on every dashboard rebuild —
    // instead of making the couple go find a "rate this vendor" button
    // themselves. Scoped per vendor id (not a single session-wide flag) so a
    // second vendor becoming rateable later in the same session still gets
    // its own prompt instead of silently never surfacing one.
    ref.listen<AsyncValue<List<VendorProfile>>>(rateableVendorsProvider,
        (previous, next) {
      final vendors = next.valueOrNull;
      if (vendors == null || vendors.isEmpty) return;
      final shown = ref.read(ratePromptShownProvider);
      VendorProfile? pending;
      for (final v in vendors) {
        if (!shown.contains(v.id)) {
          pending = v;
          break;
        }
      }
      if (pending == null) return;
      final vendor = pending;
      ref.read(ratePromptShownProvider.notifier).state = {...shown, vendor.id};
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) showRateVendorPrompt(context, ref, vendor);
      });
    });

    final shortlisted = ref.watch(wishlistedVendorsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────────
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
                  _coupleDisplayName(user?.name, couple?.partnerName),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            actions: [
              Builder(builder: (context) {
                final hasUnread = ref
                        .watch(notificationsProvider)
                        .valueOrNull
                        ?.any((n) => !n.isRead) ??
                    false;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      tooltip: 'Notifications',
                      icon: const Icon(
                        Icons.notifications_outlined,
                        color: Colors.white,
                        size: 26,
                      ),
                      onPressed: () => context.push('/notifications'),
                    ),
                    if (hasUnread)
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
                );
              }),
              IconButton(
                tooltip: 'Log out',
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white,
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
                        // go(), not push(): invitations is a shell tab, not a
                        // standalone route (unlike plan-setup above) — pushing
                        // into a shell branch from outside the shell renders
                        // blank instead of the tab's content.
                        onGuestsSetup: () =>
                            context.go('/couple/invitations'),
                      ),
                      const SizedBox(height: 24),

                      // ── Planning tools ────────────────────────────────────────
                      // One collapsible list rather than tools scattered across
                      // the dashboard and the drawer: everything a couple can
                      // *do* sits in one place, and folds away so the shortlist
                      // and checklist below get the room.
                      _PlanningToolsMenu(
                        tasksDone: tasks.where((t) => t.isCompleted).length,
                        tasksTotal: tasks.length,
                        hasBudget: couple?.hasBudget == true,
                      ),
                      const SizedBox(height: 28),

                      // ── Shortlist ─────────────────────────────────────────────
                      WedSectionHeader(
                        title: 'Your shortlist',
                        actionLabel: 'See all',
                        onSeeAll: () => context.push('/couple/wishlist'),
                      ),
                      const SizedBox(height: 12),
                      _ShortlistScroll(
                        vendors: shortlisted,
                        onTap: (id) => context.push('/couple/vendors/$id'),
                        onDiscover: () => context.go('/couple/vendors'),
                      ),
                      const SizedBox(height: 28),

                      // ── Planning Checklist ────────────────────────────────────
                      WedSectionHeader(
                        title: 'Planning checklist',
                        actionLabel: 'View all',
                        onSeeAll: () => context.push('/couple/checklist'),
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

// ── Wedding Countdown Card ─────────────────────────────────────────────────────

class _CountdownCard extends StatefulWidget {
  final dynamic couple;
  final VoidCallback onSetDate;
  const _CountdownCard({this.couple, required this.onSetDate});

  @override
  State<_CountdownCard> createState() => _CountdownCardState();
}

class _CountdownCardState extends State<_CountdownCard> {
  static final _heroImages = VendorCategoryImages.heroRotation();

  Timer? _timer;
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduceMotion = MediaQuery.of(context).disableAnimations;
      if (reduceMotion || _heroImages.length <= 1) return;
      _timer = Timer.periodic(const Duration(seconds: 6), (_) {
        if (!mounted) return;
        setState(() => _imageIndex = (_imageIndex + 1) % _heroImages.length);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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
    final couple = widget.couple;
    final hasDate = couple?.hasWeddingDate == true;

    if (!hasDate) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppColors.forestGreen.withAlpha(60),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        // Material (not Container) carries the fill color here so the
        // InkWell splash paints on top of it instead of being hidden
        // beneath an opaque Container — a plain colored Container as an
        // InkWell's child paints over and hides the ripple entirely.
        child: Material(
          color: AppColors.forestGreen,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: widget.onSetDate,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  color: AppColors.goldDeep,
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
              const Icon(Icons.chevron_right, color: AppColors.goldDeep),
            ],
          ),
        ),
          ),
        ),
      );
    }

    final days = '${couple!.daysUntilWedding}';
    final dateLabel = _formatDate(couple!.weddingDate as DateTime);

    return Container(
      height: 152,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 900),
              child: CachedNetworkImage(
                key: ValueKey(_imageIndex),
                imageUrl: _heroImages[_imageIndex],
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 300),
                placeholder: (_, _) =>
                    Container(color: AppColors.forestGreen),
                errorWidget: (_, _, _) =>
                    Container(color: AppColors.forestGreen),
              ),
            ),
            // Scrim so white/gold text stays legible over any photo — a flat
            // AppColors.primary fill used to sit behind this card, and the
            // eyebrow/day-count text was *also* AppColors.primary, making
            // both invisible; gold + white against a darkened photo fixes it.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(80),
                    Colors.black.withAlpha(150),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOUR WEDDING DAY',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateLabel,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        days,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      Text(
                        'DAYS LEFT',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          fontSize: 9,
                        ),
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

// ── Budget Overview Card ───────────────────────────────────────────────────────

class _BudgetOverviewCard extends StatelessWidget {
  final dynamic budget;
  final VoidCallback onDetails;

  const _BudgetOverviewCard({required this.budget, required this.onDetails});

  static const _catColors = AppColors.budgetCategoryColors;

  static double _metricFor(dynamic c, bool showingPlanned) =>
      showingPlanned ? c.allocatedAmount as double : c.spentAmount as double;

  @override
  Widget build(BuildContext context) {
    final total = budget.totalAmount as double;
    final spent = budget.totalSpent as double;

    // Nothing spent yet — a fresh AI-generated plan would otherwise render
    // as an empty gray bar with no legend until the couple logs their first
    // expense, hiding the very allocation they just reviewed in the wizard.
    // Preview the *planned* split instead; once real spending starts this
    // switches back to showing where the money has actually gone.
    final showingPlanned = spent <= 0;
    final categories =
        (budget.categories as List<dynamic>)
            .where((c) => _metricFor(c, showingPlanned) > 0)
            .toList()
          ..sort(
            (a, b) => _metricFor(
              b,
              showingPlanned,
            ).compareTo(_metricFor(a, showingPlanned)),
          );

    final unallocated = showingPlanned
        ? (total - (budget.totalAllocated as double)).clamp(0.0, total)
        : (total - spent).clamp(0.0, total);

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
              Expanded(
                child: Text(
                  'Budget overview',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: onDetails,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(
                      'Details',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                TextSpan(
                  text: 'spent of ZMW ${total.toStringAsFixed(0)}',
                  style: AppTextStyles.caption.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                          ? _metricFor(c, showingPlanned) / total
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
          if (showingPlanned && categories.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Planned split — switches to actual spending once you log an expense',
              style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
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
              const _LegendDot(label: 'Unallocated', color: AppColors.segmentedBarTrack),
            ],
          ),
        ],
      ),
    );
  }
}

/// The couple's planning tools, collapsed into one card.
///
/// Stateful only to own the expanded flag — the dashboard itself is a
/// ConsumerWidget, and converting the whole screen to hold one bool would be
/// a much larger change than this wrapper.
class _PlanningToolsMenu extends StatefulWidget {
  final int tasksDone;
  final int tasksTotal;
  final bool hasBudget;

  const _PlanningToolsMenu({
    required this.tasksDone,
    required this.tasksTotal,
    required this.hasBudget,
  });

  @override
  State<_PlanningToolsMenu> createState() => _PlanningToolsMenuState();
}

class _PlanningToolsMenuState extends State<_PlanningToolsMenu> {
  // Open on arrival: these are the dashboard's primary actions, not an
  // overflow menu.
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final remaining = widget.tasksTotal - widget.tasksDone;

    return ActionMenu(
      noun: 'planning tools',
      icon: Icons.checklist_rounded,
      expanded: _open,
      onToggle: () => setState(() => _open = !_open),
      items: [
        ActionMenuItem(
          icon: Icons.checklist_outlined,
          label: 'Planning checklist',
          trailing: widget.tasksTotal == 0
              ? 'Not started'
              : '$remaining left',
          badge: remaining > 0 ? '$remaining to do' : null,
          onTap: () => context.push('/couple/checklist'),
        ),
        ActionMenuItem(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Budget',
          trailing: widget.hasBudget ? 'Track spending' : 'Set it up',
          onTap: () => context.go('/couple/budget'),
        ),
        ActionMenuItem(
          icon: Icons.storefront_outlined,
          label: 'Find vendors',
          trailing: 'Browse',
          onTap: () => context.go('/couple/vendors'),
        ),
        ActionMenuItem(
          icon: Icons.mail_outlined,
          label: 'Invitations',
          trailing: 'Create & share',
          onTap: () => context.go('/couple/invitations'),
        ),
        ActionMenuItem(
          icon: Icons.event_available_outlined,
          label: 'My bookings',
          trailing: 'View',
          onTap: () => context.push(AppRoutes.coupleBookings),
        ),
      ],
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
          style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.amber.withAlpha(80)),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                    color: AppColors.goldDeep,
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
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Let AI allocate across all categories',
                        style: AppTextStyles.caption.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.goldDeep),
              ],
            ),
          ),
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
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.amber.withAlpha(80)),
          boxShadow: AppShadows.card,
        ),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onSetupGuests,
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                      color: AppColors.goldDeep,
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
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Track RSVPs once you invite guests',
                          style: AppTextStyles.caption.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.elevated,
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onSetupGuests,
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                          color: Theme.of(context).colorScheme.primary,
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
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Guests have RSVP'd to your invitation",
                        style: AppTextStyles.caption.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
      return Container(
        // Without an explicit width this shrinks to hug "Add vendors to
        // your shortlist" — a much narrower box than every other dashboard
        // section card, floating oddly to the left of the leftover space.
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 120),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.divider),
          boxShadow: AppShadows.sm,
        ),
        child: Material(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onDiscover,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.favorite_outlined,
                  color: AppColors.goldDeep,
                  size: 28,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Add vendors to your shortlist',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 172,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // +1 for the trailing "Discover more" tile, so a short shortlist
        // still reads as an inviting row instead of one lonely card.
        itemCount: vendors.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          if (i == vendors.length) {
            return _DiscoverMoreCard(onTap: onDiscover);
          }
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
    final rating = vendor.rating as double?;
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.sm,
      ),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 92,
                width: double.infinity,
                child: VendorHeroImage(
                  vendor: vendor as VendorProfile,
                  height: 92,
                  memCacheWidth: 300,
                  single: true,
                  showBadge: false,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        vendor.businessName as String,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              vendor.category as String,
                              style: AppTextStyles.caption.copyWith(
                                color: colors.onSurfaceVariant,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (rating != null) ...[
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: AppColors.goldDeep,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              rating.toStringAsFixed(1),
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Trailing tile of the shortlist row — keeps the row from ending on one
/// lonely card and gives a one-tap path back to vendor discovery.
class _DiscoverMoreCard extends StatelessWidget {
  final VoidCallback onTap;
  const _DiscoverMoreCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.amber.withAlpha(28),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: AppColors.goldDeep,
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Discover more',
                style: AppTextStyles.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Column(
            children: [
              ...tasks.map((t) => _ChecklistRow(task: t)),
              if (tasks.isEmpty)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 26, horizontal: 16),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.forestGreen.withAlpha(15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.checklist,
                          color: Theme.of(context).colorScheme.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'No tasks yet',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to set up your planning checklist — WedPilot '
                        'builds it around your wedding date.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
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
                color: done ? Theme.of(context).colorScheme.onSurfaceVariant : AppColors.textPrimary,
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
