import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/wed_card.dart';

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendor = ref.watch(vendorProfileProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.secondary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFF06292)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      vendor?.businessName ?? 'My Business',
                      style: AppTextStyles.displaySmall.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (vendor?.category != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              vendor!.category,
                              style: AppTextStyles.caption
                                  .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (vendor?.rating != null)
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                              const SizedBox(width: 3),
                              Text(
                                '${vendor!.rating!.toStringAsFixed(1)} (${vendor.reviewCount} reviews)',
                                style: AppTextStyles.caption.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () => context.push('/notifications'),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                onPressed: () => context.push('/settings'),
                tooltip: 'Settings',
              ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── KPI Stats Row ──────────────────────────────────
                Row(
                  children: [
                    _KpiCard(
                      value: '24',
                      label: 'Profile Views',
                      icon: Icons.visibility_outlined,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 10),
                    _KpiCard(
                      value: '5',
                      label: 'New Leads',
                      icon: Icons.mail_outline,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 10),
                    _KpiCard(
                      value: '87%',
                      label: 'Match Score',
                      icon: Icons.star_outline,
                      color: AppColors.goldPremium,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Earnings Overview ──────────────────────────────
                _SectionHeader(title: 'Earnings Overview'),
                const SizedBox(height: 12),
                _EarningsCard(),
                const SizedBox(height: 20),

                // ── Profile Completion ─────────────────────────────
                WedCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Profile Completion',
                              style: AppTextStyles.headlineSmall),
                          Text(
                            '75%',
                            style: AppTextStyles.headlineSmall
                                .copyWith(color: AppColors.secondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: 0.75,
                        backgroundColor: AppColors.divider,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.secondary),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: const [
                          _CompletionChip(label: 'Bio ✓', done: true),
                          _CompletionChip(label: 'Photos', done: false),
                          _CompletionChip(label: 'Services ✓', done: true),
                          _CompletionChip(label: 'Location ✓', done: true),
                          _CompletionChip(label: 'Pricing', done: false),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Booking Requests ───────────────────────────────
                _SectionHeader(
                  title: 'Booking Requests',
                  actionLabel: 'View all',
                  onAction: () => context.push('/vendor/leads'),
                ),
                const SizedBox(height: 12),
                _BookingRequestsSection(),
                const SizedBox(height: 20),

                // ── Upcoming Events ────────────────────────────────
                _SectionHeader(
                  title: 'Upcoming Events',
                  actionLabel: 'Calendar',
                  onAction: () => context.push('/vendor/availability'),
                ),
                const SizedBox(height: 12),
                _UpcomingEventsSection(),
                const SizedBox(height: 20),

                // ── Quick Nav ──────────────────────────────────────
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    _NavCard(
                      emoji: '💬',
                      title: 'Messages',
                      subtitle: '2 unread',
                      color: AppColors.info.withAlpha(26),
                      onTap: () => context.push('/vendor/messages'),
                    ),
                    _NavCard(
                      emoji: '📊',
                      title: 'Analytics',
                      subtitle: 'View insights',
                      color: AppColors.primary.withAlpha(77),
                      onTap: () => context.push('/vendor/analytics'),
                    ),
                    _NavCard(
                      emoji: '👤',
                      title: 'Edit Profile',
                      subtitle: 'Update details',
                      color: AppColors.tertiary.withAlpha(51),
                      onTap: () => context.push('/vendor/profile'),
                    ),
                    _NavCard(
                      emoji: '📅',
                      title: 'Availability',
                      subtitle: 'Manage calendar',
                      color: AppColors.warning.withAlpha(26),
                      onTap: () => context.push('/vendor/availability'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Subscription Banner ────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.goldPremium, AppColors.roseGoldPremium],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 28)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upgrade to Premium',
                              style: AppTextStyles.titleMedium
                                  .copyWith(color: Colors.white),
                            ),
                            Text(
                              'Priority placement + unlimited portfolio',
                              style: AppTextStyles.caption
                                  .copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.push('/vendor/subscription'),
                        child: const Text(
                          'Upgrade',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Earnings Card ──────────────────────────────────────────────────────────────

class _EarningsCard extends StatelessWidget {
  const _EarningsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This Month',
                style: AppTextStyles.labelMedium.copyWith(color: Colors.white70),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Jun 2026',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$4,200',
            style: AppTextStyles.displaySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: Colors.greenAccent, size: 14),
              const SizedBox(width: 4),
              Text(
                '+18% vs last month',
                style: AppTextStyles.caption.copyWith(color: Colors.greenAccent),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _EarningsMetric(
                  label: 'Total Bookings',
                  value: '12',
                  icon: Icons.calendar_month_rounded,
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white24),
              Expanded(
                child: _EarningsMetric(
                  label: 'Avg. Booking',
                  value: '\$350',
                  icon: Icons.attach_money_rounded,
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white24),
              Expanded(
                child: _EarningsMetric(
                  label: 'Conversion',
                  value: '68%',
                  icon: Icons.show_chart_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EarningsMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _EarningsMetric(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(value,
            style: AppTextStyles.titleMedium.copyWith(
                color: Colors.white, fontWeight: FontWeight.w700)),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(color: Colors.white60, fontSize: 10),
            textAlign: TextAlign.center),
      ],
    );
  }
}

// ── Booking Requests Section ───────────────────────────────────────────────────

class _BookingRequestsSection extends StatelessWidget {
  const _BookingRequestsSection();

  static const _requests = [
    _RequestData(
      coupleInitials: 'SJ',
      coupleName: 'Sarah & James',
      event: 'Wedding · Aug 12, 2027',
      note: 'Looking for a photojournalism style photographer',
      isNew: true,
    ),
    _RequestData(
      coupleInitials: 'MT',
      coupleName: 'Maya & Thomas',
      event: 'Wedding · Oct 5, 2027',
      note: 'Interested in a full-day coverage package',
      isNew: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_requests.isEmpty) {
      return WedCard(
        child: Row(
          children: [
            const Text('📭', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No pending requests', style: AppTextStyles.titleMedium),
                  Text('Booking requests will appear here',
                      style: AppTextStyles.caption.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      )),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _requests
          .map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BookingRequestTile(request: r),
              ))
          .toList(),
    );
  }
}

class _RequestData {
  final String coupleInitials;
  final String coupleName;
  final String event;
  final String note;
  final bool isNew;

  const _RequestData({
    required this.coupleInitials,
    required this.coupleName,
    required this.event,
    required this.note,
    required this.isNew,
  });
}

class _BookingRequestTile extends StatelessWidget {
  final _RequestData request;
  const _BookingRequestTile({required this.request});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.secondary.withAlpha(26),
            child: Text(
              request.coupleInitials,
              style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.secondary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(request.coupleName, style: AppTextStyles.titleMedium),
                    if (request.isNew) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'NEW',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  request.event,
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.secondary, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  request.note,
                  style: AppTextStyles.caption.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ActionChip(
                      label: 'Accept',
                      color: AppColors.success,
                      onTap: () {},
                    ),
                    const SizedBox(width: 8),
                    _ActionChip(
                      label: 'Decline',
                      color: AppColors.textSecondary,
                      outlined: true,
                      onTap: () {},
                    ),
                    const SizedBox(width: 8),
                    _ActionChip(
                      label: 'Message',
                      color: AppColors.info,
                      outlined: true,
                      onTap: () => context.push('/vendor/messages'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionChip({
    required this.label,
    required this.color,
    this.outlined = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: outlined ? Colors.transparent : color.withAlpha(26),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: outlined ? cs.outlineVariant : color.withAlpha(80)),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: outlined ? cs.onSurface.withValues(alpha: 0.6) : color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Upcoming Events Section ────────────────────────────────────────────────────

class _UpcomingEventsSection extends StatelessWidget {
  const _UpcomingEventsSection();

  static const _events = [
    _EventData(
      emoji: '📸',
      coupleName: 'Alex & Jordan',
      eventType: 'Wedding Photography',
      date: 'Sun, Jun 14, 2026',
      time: '10:00 AM',
      location: 'Central Park, New York',
    ),
    _EventData(
      emoji: '💑',
      coupleName: 'Nina & Carlos',
      eventType: 'Engagement Shoot',
      date: 'Sat, Jun 21, 2026',
      time: '4:00 PM',
      location: 'Brooklyn Bridge, New York',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_events.isEmpty) {
      return WedCard(
        child: Row(
          children: [
            const Text('📅', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No upcoming events', style: AppTextStyles.titleMedium),
                  Text('Confirmed bookings will appear here',
                      style: AppTextStyles.caption.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      )),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _events
          .map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _EventTile(event: e),
              ))
          .toList(),
    );
  }
}

class _EventData {
  final String emoji;
  final String coupleName;
  final String eventType;
  final String date;
  final String time;
  final String location;

  const _EventData({
    required this.emoji,
    required this.coupleName,
    required this.eventType,
    required this.date,
    required this.time,
    required this.location,
  });
}

class _EventTile extends StatelessWidget {
  final _EventData event;
  const _EventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dimText = cs.onSurface.withValues(alpha: 0.6);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.secondary.withAlpha(18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(event.emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.coupleName, style: AppTextStyles.titleMedium),
                const SizedBox(height: 1),
                Text(
                  event.eventType,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 11, color: dimText),
                    const SizedBox(width: 3),
                    Text(
                      '${event.date} · ${event.time}',
                      style: AppTextStyles.caption.copyWith(color: dimText),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 11, color: dimText),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        event.location,
                        style: AppTextStyles.caption.copyWith(color: dimText),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.headlineSmall),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.secondary),
            ),
          ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _KpiCard(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: AppTextStyles.headlineSmall.copyWith(color: color)),
            Text(label,
                style: AppTextStyles.caption.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _CompletionChip extends StatelessWidget {
  final String label;
  final bool done;
  const _CompletionChip({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Chip(
      label: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: done ? AppColors.success : cs.onSurface.withValues(alpha: 0.6),
        ),
      ),
      backgroundColor: done
          ? AppColors.success.withAlpha(26)
          : cs.surfaceContainerHighest,
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _NavCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _NavCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium),
                Text(subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
