import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/state/resource.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/messaging.dart';
import '../../../providers/vendor_own_provider.dart';

class LeadInboxScreen extends ConsumerStatefulWidget {
  const LeadInboxScreen({super.key});

  @override
  ConsumerState<LeadInboxScreen> createState() => _LeadInboxScreenState();
}

class _LeadInboxScreenState extends ConsumerState<LeadInboxScreen> {
  int _filterIndex = 0;

  List<Inquiry> _filtered(List<Inquiry> all) {
    if (_filterIndex == 1) {
      return all.where((i) => i.status == InquiryStatus.newInquiry).toList();
    }
    if (_filterIndex == 2) {
      return all.where((i) => i.status == InquiryStatus.booked).toList();
    }
    return all;
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(vendorOwnProvider).status == ResourceStatus.initial) {
      Future.microtask(() => ref.read(vendorOwnProvider.notifier).loadOwnVendorData());
    }
    final inquiries = ref.watch(vendorInquiriesProvider);
    final unreadCount =
        inquiries.where((i) => i.status == InquiryStatus.newInquiry).length;
    final filtered = _filtered(inquiries);

    final filters = [
      'All (${inquiries.length})',
      'Unread ($unreadCount)',
      'Booked',
    ];

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────────────
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
                        '${inquiries.length} TOTAL INQUIRIES',
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

          // ── Filter pills ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.cream,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: List.generate(filters.length, (i) {
                  final active = i == _filterIndex;
                  return Padding(
                    padding: EdgeInsets.only(
                        right: i < filters.length - 1 ? 8 : 0),
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
                          filters[i],
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

          // ── Lead list ─────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
            sliver: filtered.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
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
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _LeadCard(
                          inquiry: filtered[i],
                          onTap: () {
                            ref
                                .read(vendorOwnProvider.notifier)
                                .markInquiryStatus(
                                    filtered[i].id, InquiryStatus.viewed);
                            context.push(AppRoutes.vendorMessages);
                          },
                        ),
                      ),
                      childCount: filtered.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Lead card ─────────────────────────────────────────────────────────────────

class _LeadCard extends StatelessWidget {
  final Inquiry inquiry;
  final VoidCallback onTap;

  const _LeadCard({required this.inquiry, required this.onTap});

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.split(RegExp(r'[\s&]+'));
    return parts
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return DateFormat('MMM d').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isUnread = inquiry.status == InquiryStatus.newInquiry;
    final isBooked = inquiry.status == InquiryStatus.booked;
    final name = inquiry.coupleName ?? 'Unknown couple';

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
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.cream,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _initials(name),
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
                      Text(name,
                          style: AppTextStyles.titleMedium
                              .copyWith(color: AppColors.forestGreen)),
                      Text(
                        inquiry.message,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
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
                    Text(_timeAgo(inquiry.createdAt),
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
            Wrap(
              spacing: 6,
              children: [
                if (isBooked)
                  _Chip(label: 'Booked', color: AppColors.success)
                else ...[
                  if (inquiry.weddingDate != null)
                    _Chip(
                      label: DateFormat('MMM d, y')
                          .format(inquiry.weddingDate!),
                      color: AppColors.forestGreen,
                    ),
                  if (inquiry.budgetRangeMin != null)
                    _Chip(
                      label:
                          'ZMW ${inquiry.budgetRangeMin!.toStringAsFixed(0)}–${inquiry.budgetRangeMax?.toStringAsFixed(0) ?? '?'}',
                      color: AppColors.textSecondary,
                    ),
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
