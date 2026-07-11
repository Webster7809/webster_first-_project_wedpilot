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
import '../../../widgets/wed_snack_bar.dart';
import '../../../widgets/wed_text_field.dart';

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

  void _openDetail(String inquiryId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LeadDetailSheet(inquiryId: inquiryId),
    );
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
                    child: Material(
                      animationDuration: const Duration(milliseconds: 200),
                      color: active ? AppColors.forestGreen : Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: active ? AppColors.forestGreen : AppColors.divider,
                          width: 1.5,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => setState(() => _filterIndex = i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 8),
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
                          onTap: () => _openDetail(filtered[i].id),
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
    final isDeclined = inquiry.status == InquiryStatus.declined;
    final name = inquiry.coupleName ?? 'Unknown couple';

    return Container(
      decoration: BoxDecoration(
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
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.all(16),
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
                              .copyWith(color: AppColors.forestGreen),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
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
                else if (isDeclined)
                  _Chip(label: 'Declined', color: AppColors.error)
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
                if (isBooked && !inquiry.hasFeedback)
                  _Chip(
                    label: inquiry.serviceDoneAt == null
                        ? 'Awaiting service'
                        : 'Awaiting rating',
                    color: AppColors.amber,
                  ),
              ],
            ),
          ],
        ),
        ),
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

// ── Lead detail sheet ────────────────────────────────────────────────────────

class _LeadDetailSheet extends ConsumerStatefulWidget {
  final String inquiryId;
  const _LeadDetailSheet({required this.inquiryId});

  @override
  ConsumerState<_LeadDetailSheet> createState() => _LeadDetailSheetState();
}

class _LeadDetailSheetState extends ConsumerState<_LeadDetailSheet> {
  bool _isBusy = false;

  Future<void> _accept(Inquiry inquiry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept this booking?'),
        content: Text(
          inquiry.weddingDate != null
              ? 'This confirms the booking with ${inquiry.coupleName ?? 'this couple'} and blocks ${DateFormat('MMM d, y').format(inquiry.weddingDate!)} on your calendar.'
              : 'This confirms the booking with ${inquiry.coupleName ?? 'this couple'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isBusy = true);
    final error = await ref
        .read(vendorOwnProvider.notifier)
        .markInquiryStatus(inquiry.id, InquiryStatus.booked);
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (error != null) {
      showWedSnackBar(context, error, type: SnackType.error);
    } else {
      showWedSnackBar(context, 'Booking confirmed!', type: SnackType.success);
    }
  }

  Future<void> _decline(Inquiry inquiry) async {
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DeclineReasonSheet(),
    );
    if (reason == null || reason.trim().isEmpty) return;

    setState(() => _isBusy = true);
    final error = await ref.read(vendorOwnProvider.notifier).markInquiryStatus(
          inquiry.id,
          InquiryStatus.declined,
          declineReason: reason.trim(),
        );
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (error != null) {
      showWedSnackBar(context, error, type: SnackType.error);
    } else {
      showWedSnackBar(context, 'Inquiry declined.', type: SnackType.info);
    }
  }

  Future<void> _notifyToRate(Inquiry inquiry) async {
    setState(() => _isBusy = true);
    final error =
        await ref.read(vendorOwnProvider.notifier).markServiceDone(inquiry.id);
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (error != null) {
      showWedSnackBar(context, error, type: SnackType.error);
    } else {
      showWedSnackBar(context, 'Couple notified to rate you.',
          type: SnackType.success);
    }
  }

  void _messageCouple(Inquiry inquiry) {
    ref
        .read(vendorOwnProvider.notifier)
        .markInquiryStatus(inquiry.id, InquiryStatus.viewed);
    Navigator.pop(context);
    context.push(AppRoutes.vendorMessages);
  }

  @override
  Widget build(BuildContext context) {
    final inquiries = ref.watch(vendorInquiriesProvider);
    final inquiry = inquiries.where((i) => i.id == widget.inquiryId).firstOrNull;
    if (inquiry == null) return const SizedBox.shrink();

    final isPending = inquiry.status != InquiryStatus.booked &&
        inquiry.status != InquiryStatus.declined;
    final name = inquiry.coupleName ?? 'Unknown couple';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(name,
                style: AppTextStyles.headlineMedium
                    .copyWith(color: AppColors.forestGreen)),
            const SizedBox(height: 8),
            Text(
              inquiry.message,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (inquiry.weddingDate != null)
                  _DetailPill(
                    icon: Icons.calendar_today_outlined,
                    label: DateFormat('MMM d, y').format(inquiry.weddingDate!),
                  ),
                if (inquiry.budgetRangeMin != null)
                  _DetailPill(
                    icon: Icons.payments_outlined,
                    label:
                        'ZMW ${inquiry.budgetRangeMin!.toStringAsFixed(0)}–${inquiry.budgetRangeMax?.toStringAsFixed(0) ?? '?'}',
                  ),
              ],
            ),
            if (inquiry.status == InquiryStatus.declined &&
                inquiry.declineReason != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.errorBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'You declined: ${inquiry.declineReason}',
                  style:
                      AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                ),
              ),
            ],
            const SizedBox(height: 20),

            if (isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isBusy ? null : () => _decline(inquiry),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isBusy ? null : () => _accept(inquiry),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: _isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Accept Booking'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],

            if (inquiry.status == InquiryStatus.booked) ...[
              _ServiceDoneSection(
                inquiry: inquiry,
                isBusy: _isBusy,
                onNotify: () => _notifyToRate(inquiry),
              ),
              const SizedBox(height: 10),
            ],

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _messageCouple(inquiry),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: const Text('Message couple'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.forestGreen,
                  side: const BorderSide(color: AppColors.divider),
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.creamDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.forestGreen),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.forestGreen, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── "Notify couple to rate" section (shown once a lead is booked) ─────────────

class _ServiceDoneSection extends StatelessWidget {
  final Inquiry inquiry;
  final bool isBusy;
  final VoidCallback onNotify;

  const _ServiceDoneSection({
    required this.inquiry,
    required this.isBusy,
    required this.onNotify,
  });

  @override
  Widget build(BuildContext context) {
    if (inquiry.hasFeedback) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.successBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_outline, size: 18, color: AppColors.success),
            const SizedBox(width: 8),
            Text('Rated by this couple',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.success)),
          ],
        ),
      );
    }

    if (inquiry.ratingReminderCount >= 2) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.creamDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Reminder limit reached (2/2 sent) — waiting on the couple to rate you.',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final isFirst = inquiry.ratingReminderCount == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isFirst
              ? 'Once the wedding/service is done, let the couple know so they can rate you.'
              : "The couple hasn't rated you yet. You have one final reminder left.",
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isBusy ? null : onNotify,
            icon: const Icon(Icons.notifications_active_outlined, size: 16),
            label: Text(isFirst ? 'Notify Couple to Rate' : 'Send Reminder (Final Chance)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.amber,
              side: const BorderSide(color: AppColors.amber),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Decline reason sheet ────────────────────────────────────────────────────

const _kDeclineReasons = [
  'Fully booked on this date',
  'Outside our service area',
  "Budget doesn't align",
  'Not the right fit',
  'Other',
];

class _DeclineReasonSheet extends StatefulWidget {
  const _DeclineReasonSheet();

  @override
  State<_DeclineReasonSheet> createState() => _DeclineReasonSheetState();
}

class _DeclineReasonSheetState extends State<_DeclineReasonSheet> {
  String? _selected;
  final _otherCtrl = TextEditingController();

  @override
  void dispose() {
    _otherCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final reason = _selected == 'Other' ? _otherCtrl.text.trim() : _selected;
    if (reason == null || reason.isEmpty) return;
    Navigator.pop(context, reason);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Why are you declining?',
                style: AppTextStyles.headlineMedium
                    .copyWith(color: AppColors.forestGreen)),
            const SizedBox(height: 4),
            Text(
              'A short reason helps the couple understand — this is shared with them.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kDeclineReasons.map((reason) {
                final selected = _selected == reason;
                return ChoiceChip(
                  label: Text(reason),
                  selected: selected,
                  onSelected: (_) => setState(() => _selected = reason),
                  selectedColor: AppColors.forestGreen,
                  labelStyle: AppTextStyles.labelMedium.copyWith(
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                  backgroundColor: AppColors.creamDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: selected ? AppColors.forestGreen : AppColors.divider,
                    ),
                  ),
                );
              }).toList(),
            ),
            if (_selected == 'Other') ...[
              const SizedBox(height: 16),
              WedTextField(
                label: 'Reason',
                hint: 'Tell them briefly why…',
                controller: _otherCtrl,
                maxLines: 3,
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selected == null ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: const Text('Decline Inquiry',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
