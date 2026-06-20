import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class LeadInboxScreen extends StatefulWidget {
  const LeadInboxScreen({super.key});

  @override
  State<LeadInboxScreen> createState() => _LeadInboxScreenState();
}

class _LeadInboxScreenState extends State<LeadInboxScreen> {
  int _filterIndex = 0;

  static const _filters = ['All (6)', 'Unread (2)', 'Booked'];

  static final _leads = [
    _Lead(
      initials: 'CM',
      name: 'Chanda & Mwila',
      timeAgo: '10 min ago',
      message: 'Hi, is the garden available 12 September?...',
      guests: 180,
      tier: 'Flexible tier',
      status: _LeadStatus.unread,
    ),
    _Lead(
      initials: 'BK',
      name: 'Bwalya & Kunda',
      timeAgo: '2 hr ago',
      message: 'Good day, do you offer a discount for wee...',
      guests: 220,
      tier: 'High class',
      status: _LeadStatus.unread,
    ),
    _Lead(
      initials: 'NT',
      name: 'Natasha & Temba',
      timeAgo: 'Yesterday',
      message: 'Thank you so much, we\'d like to confirm t...',
      guests: null,
      tier: null,
      status: _LeadStatus.booked,
    ),
    _Lead(
      initials: 'MP',
      name: 'Mutale & Phiri',
      timeAgo: '3 days ago',
      message: 'Is parking available for around 60 vehicle...',
      guests: 150,
      tier: 'Flexible tier',
      status: _LeadStatus.read,
    ),
    _Lead(
      initials: 'RC',
      name: 'Ruth & Chola',
      timeAgo: '5 days ago',
      message: 'We loved the venue photos! Could we sch...',
      guests: 300,
      tier: 'High class',
      status: _LeadStatus.read,
    ),
  ];

  List<_Lead> get _filtered {
    if (_filterIndex == 1) return _leads.where((l) => l.status == _LeadStatus.unread).toList();
    if (_filterIndex == 2) return _leads.where((l) => l.status == _LeadStatus.booked).toList();
    return _leads;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: false,
            backgroundColor: AppColors.forestGreen,
            expandedHeight: 120,
            elevation: 0,
            automaticallyImplyLeading: false,
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
                        '38 TOTAL INQUIRIES',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.amber,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Couples reaching out',
                        style: AppTextStyles.headlineMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Filter pills ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.cream,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: List.generate(_filters.length, (i) {
                  final active = i == _filterIndex;
                  return Padding(
                    padding: EdgeInsets.only(right: i < _filters.length - 1 ? 8 : 0),
                    child: GestureDetector(
                      onTap: () => setState(() => _filterIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 8),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.forestGreen
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: active
                                ? AppColors.forestGreen
                                : AppColors.divider,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _filters[i],
                          style: AppTextStyles.labelMedium.copyWith(
                            color: active
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // ── Lead list ────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final leads = _filtered;
                  if (leads.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          const Icon(Icons.inbox_outlined,
                              size: 48, color: AppColors.textHint),
                          const SizedBox(height: 12),
                          Text('No inquiries here',
                              style: AppTextStyles.headlineSmall
                                  .copyWith(color: AppColors.textSecondary)),
                        ],
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _LeadCard(
                      lead: leads[i],
                      onTap: () => context.push('/vendor/messages'),
                    ),
                  );
                },
                childCount: _filtered.isEmpty ? 1 : _filtered.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data ───────────────────────────────────────────────────────────────────────

enum _LeadStatus { unread, read, booked }

class _Lead {
  final String initials;
  final String name;
  final String timeAgo;
  final String message;
  final int? guests;
  final String? tier;
  final _LeadStatus status;

  const _Lead({
    required this.initials,
    required this.name,
    required this.timeAgo,
    required this.message,
    required this.guests,
    required this.tier,
    required this.status,
  });
}

// ── Lead card ──────────────────────────────────────────────────────────────────

class _LeadCard extends StatelessWidget {
  final _Lead lead;
  final VoidCallback onTap;

  const _LeadCard({required this.lead, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isUnread = lead.status == _LeadStatus.unread;
    final isBooked = lead.status == _LeadStatus.booked;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isUnread
              ? Border.all(color: AppColors.amber, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.forestGreen.withAlpha(12),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      lead.initials,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.amber,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lead.name,
                          style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.forestGreen)),
                      Text(
                        lead.message,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(lead.timeAgo,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                    if (isUnread) ...[
                      const SizedBox(height: 6),
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: AppColors.amber,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Tag chips
            Wrap(
              spacing: 6,
              children: [
                if (isBooked)
                  _Chip(label: 'Booked', color: AppColors.success)
                else ...[
                  if (lead.guests != null)
                    _Chip(
                      label: '${lead.guests} guests',
                      color: AppColors.forestGreen,
                    ),
                  if (lead.tier != null)
                    _Chip(label: lead.tier!, color: AppColors.textSecondary),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
