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
import '../../../widgets/hamburger_menu_button.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_chip.dart';
import '../../../widgets/wed_empty_state.dart';
import '../../../widgets/wed_snack_bar.dart';

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
            leading: const HamburgerMenuButton(color: Colors.white),
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
                          // Gold on the forest header — 4.99:1.
                          color: AppColors.gold,
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
              // Wrap, not Row: four fixed-width pills overflowed by 27px on a
              // 412pt phone, and a filter you cannot see is a filter you
              // cannot use. Wrapping to a second line keeps every one of them
              // reachable at any width or text scale.
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(filters.length, (i) {
                  final active = i == _filterIndex;
                  return Padding(
                    padding: EdgeInsets.zero,
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
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 28),
                      child: WedEmptyState(
                        icon: Icons.inbox_outlined,
                        title: 'No inquiries here',
                        message: 'New booking requests will show up here.',
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

/// Still awaiting the vendor's answer — the only state where accept/decline
/// mean anything.
bool _isPendingLead(Inquiry i) =>
    i.status != InquiryStatus.booked &&
    i.status != InquiryStatus.declined &&
    i.status != InquiryStatus.cancelled;

/// Accept in one tap, with a 6-second UNDO in place of a confirmation dialog.
///
/// Confirming a booking used to cost four taps through a dialog stacked on
/// top of the lead sheet. A vendor works through leads all day, so the happy
/// path is now immediate and the safety net is the undo — the same shape the
/// couple's own booking button already uses.
///
/// Undo is safe rather than cosmetic: moving an inquiry back out of 'booked'
/// makes the backend release the calendar hold that accepting placed and
/// delete the "confirmed!" notification the couple was just sent.
Future<void> acceptLead(
  BuildContext context,
  WidgetRef ref,
  Inquiry inquiry,
) async {
  // A lead that had never been opened goes back as 'viewed', not
  // 'newInquiry' — by the time you can undo, you have certainly seen it.
  final revertTo = inquiry.status == InquiryStatus.newInquiry
      ? InquiryStatus.viewed
      : inquiry.status;

  final (error, convoId) = await ref
      .read(vendorOwnProvider.notifier)
      .markInquiryStatus(inquiry.id, InquiryStatus.booked);
  if (!context.mounted) return;
  if (error != null) {
    showWedSnackBar(context, error, type: SnackType.error);
    return;
  }

  final coupleName = inquiry.coupleName ?? 'this couple';

  // The backend creates the conversation thread the moment a booking is
  // confirmed (see services/inquiryStatus.js) specifically so this prompt can
  // drop straight into a real chat instead of an empty inbox — accepting is
  // exactly when a vendor should say hello, not whenever they happen to
  // notice the "Message couple" button buried in the detail sheet.
  if (convoId != null) {
    final wantsToMessage = await showDialog<bool>(
      context: context,
      builder: (_) => _BookingConfirmedDialog(coupleName: coupleName),
    );
    if (!context.mounted) return;
    if (wantsToMessage == true) {
      context.push('/vendor/messages/$convoId');
      return;
    }
  }

  showWedSnackBar(
    context,
    'Booked with $coupleName.',
    type: SnackType.success,
    actionLabel: 'UNDO',
    onAction: () async {
      final (undoError, _) = await ref
          .read(vendorOwnProvider.notifier)
          .markInquiryStatus(inquiry.id, revertTo);
      if (!context.mounted) return;
      showWedSnackBar(
        context,
        undoError ?? 'Undone — the lead is back in your inbox.',
        type: undoError != null ? SnackType.error : SnackType.info,
      );
    },
  );
}

/// Marks a booked engagement's service as fulfilled and prompts the couple to
/// rate the vendor — the same action as [_ServiceDoneSection]'s button, now
/// also reachable directly from the card so it doesn't require opening the
/// detail sheet to find.
Future<void> markComplete(
  BuildContext context,
  WidgetRef ref,
  Inquiry inquiry,
) async {
  final error =
      await ref.read(vendorOwnProvider.notifier).markServiceDone(inquiry.id);
  if (!context.mounted) return;
  showWedSnackBar(
    context,
    error ??
        'Marked complete — ${inquiry.coupleName ?? 'the couple'} can now rate you.',
    type: error != null ? SnackType.error : SnackType.success,
  );
}

class _BookingConfirmedDialog extends StatelessWidget {
  final String coupleName;
  const _BookingConfirmedDialog({required this.coupleName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Booking confirmed!'),
      content: Text(
        '$coupleName has been notified. Send them a message now to '
        'introduce yourself and go over the details?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Later'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.forestGreen),
          child: const Text('Message Now'),
        ),
      ],
    );
  }
}

/// Decline keeps its confirmation, unlike accept: it is final for the couple,
/// they are notified straight away, and nothing on their side can reverse it.
Future<void> declineLead(
  BuildContext context,
  WidgetRef ref,
  Inquiry inquiry,
) async {
  final reason = await showDialog<String>(
    context: context,
    builder: (_) =>
        _DeclineConfirmDialog(coupleName: inquiry.coupleName ?? 'this couple'),
  );
  if (reason == null || !context.mounted) return;

  final (error, _) = await ref.read(vendorOwnProvider.notifier).markInquiryStatus(
        inquiry.id,
        InquiryStatus.declined,
        declineReason: reason.trim(),
      );
  if (!context.mounted) return;
  showWedSnackBar(
    context,
    error ?? 'Declined. ${inquiry.coupleName ?? 'The couple'} has been told.',
    type: error != null ? SnackType.error : SnackType.info,
  );
}

class _LeadCard extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final isUnread = inquiry.status == InquiryStatus.newInquiry;
    final isBooked = inquiry.status == InquiryStatus.booked;
    final isDeclined = inquiry.status == InquiryStatus.declined;
    final isCancelled = inquiry.status == InquiryStatus.cancelled;
    final name = inquiry.coupleName ?? 'Unknown couple';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // goldDeep, not gold: this border is the only thing marking a lead as
        // unread, so it has to clear 3:1 against the white card (4.86:1).
        border: isUnread
            ? Border.all(color: AppColors.goldDeep, width: 1.5)
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
                        color: AppColors.primary,
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
                else if (isCancelled)
                  _Chip(label: 'Cancelled by couple', color: AppColors.textSecondary)
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

            // Answering a lead is the whole job of this screen, so both
            // answers sit on the card itself. Opening the detail sheet is now
            // for reading the couple's message, not for reaching the buttons.
            if (_isPendingLead(inquiry)) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: WedButton(
                      label: 'Decline',
                      variant: WedButtonVariant.secondary,
                      height: 42,
                      borderRadius: 12,
                      fontSize: 14,
                      onPressed: () => declineLead(context, ref, inquiry),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: WedButton(
                      label: 'Accept',
                      variant: WedButtonVariant.success,
                      height: 42,
                      borderRadius: 12,
                      fontSize: 14,
                      onPressed: () => acceptLead(context, ref, inquiry),
                    ),
                  ),
                ],
              ),
            ],

            // The prominent, on-card counterpart to accept/decline for the
            // next step in a booking's life — previously the only way to mark
            // a booking complete was to open the detail sheet and find the
            // button buried inside it.
            if (isBooked && inquiry.serviceDoneAt == null && !inquiry.hasFeedback) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: WedButton(
                  label: 'Mark Booking Complete',
                  variant: WedButtonVariant.accent,
                  height: 42,
                  borderRadius: 12,
                  fontSize: 14,
                  icon: const Icon(Icons.task_alt_outlined, size: 16),
                  onPressed: () => markComplete(context, ref, inquiry),
                ),
              ),
            ],
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

  // Both answers go through the same shared helpers the lead card uses, so
  // accepting from the sheet and accepting from the card behave identically —
  // one tap, undo on the accept, confirmation only on the decline. The sheet
  // closes first: leaving it open would put the undo snack bar behind it.
  // The sheet closes first, so the snack bar and its undo aren't buried
  // behind it. That means handing the helpers the navigator's context rather
  // than this sheet's: the sheet's is unmounted the moment it pops, and
  // every `context.mounted` guard downstream would bail out, leaving the
  // vendor with a silent accept and no undo at all.
  Future<void> _accept(Inquiry inquiry) async {
    final host = Navigator.of(context).context;
    Navigator.pop(context);
    await acceptLead(host, ref, inquiry);
  }

  Future<void> _decline(Inquiry inquiry) async {
    final host = Navigator.of(context).context;
    Navigator.pop(context);
    await declineLead(host, ref, inquiry);
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
      showWedSnackBar(context, 'Marked complete — the couple can now rate you.',
          type: SnackType.success);
    }
  }

  void _messageCouple(Inquiry inquiry) {
    // Only a lead that has never been opened gets marked as read here.
    //
    // This used to write `viewed` unconditionally, which meant messaging a
    // couple you had already booked *un-booked them*: the backend treats any
    // move out of 'booked' as an undo, so it released the wedding date from
    // the calendar and deleted the couple's "confirmed!" notification. A
    // vendor sending a friendly message silently cancelled the booking.
    if (inquiry.status == InquiryStatus.newInquiry) {
      ref
          .read(vendorOwnProvider.notifier)
          .markInquiryStatus(inquiry.id, InquiryStatus.viewed);
    }
    Navigator.pop(context);
    context.push(AppRoutes.vendorMessages);
  }

  @override
  Widget build(BuildContext context) {
    final inquiries = ref.watch(vendorInquiriesProvider);
    final inquiry = inquiries.where((i) => i.id == widget.inquiryId).firstOrNull;
    if (inquiry == null) return const SizedBox.shrink();

    final isPending = inquiry.status != InquiryStatus.booked &&
        inquiry.status != InquiryStatus.declined &&
        inquiry.status != InquiryStatus.cancelled;
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
            if (inquiry.status == InquiryStatus.cancelled) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.creamDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'This couple cancelled the request.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
            const SizedBox(height: 20),

            if (isPending) ...[
              Row(
                children: [
                  Expanded(
                    child: WedButton(
                      label: 'Decline',
                      variant: WedButtonVariant.danger,
                      onPressed: _isBusy ? null : () => _decline(inquiry),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: WedButton(
                      label: 'Accept Booking',
                      variant: WedButtonVariant.success,
                      isLoading: _isBusy,
                      onPressed: _isBusy ? null : () => _accept(inquiry),
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
                icon: const Icon(Icons.chat_bubble_outlined, size: 16),
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
            const Icon(Icons.check_circle_outlined, size: 18, color: AppColors.success),
            const SizedBox(width: 8),
            Text('Rated by this couple',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.success)),
          ],
        ),
      );
    }

    if (inquiry.ratingReminderCount >= 1) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.creamDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          "Reminder sent — waiting on the couple to rate you.",
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Once the wedding/service is done, mark it complete so the couple can rate you.',
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isBusy ? null : onNotify,
            icon: const Icon(Icons.task_alt_outlined, size: 16),
            label: const Text('Mark Booking Complete'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Decline confirmation ────────────────────────────────────────────────────

const _kDeclineReasons = [
  'Fully booked on this date',
  'Outside our service area',
  "Budget doesn't align",
  'Not the right fit',
];

/// Confirms a decline, mirroring the Accept dialog so answering a lead either
/// way is one decision plus one confirmation.
///
/// The reason is genuinely optional. It used to be mandatory — the vendor had
/// to pick a chip (and type free text for "Other") before the button even
/// enabled — which made saying no meaningfully harder than saying yes for no
/// good reason. A reason is still offered because the couple sees it, and
/// [_kDefaultDeclineReason] stands in when none is given, since the API
/// requires a non-empty one.
const _kDefaultDeclineReason = 'The vendor is not available for this booking';

class _DeclineConfirmDialog extends StatefulWidget {
  final String coupleName;

  const _DeclineConfirmDialog({required this.coupleName});

  @override
  State<_DeclineConfirmDialog> createState() => _DeclineConfirmDialogState();
}

class _DeclineConfirmDialogState extends State<_DeclineConfirmDialog> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Decline this booking?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to decline ${widget.coupleName}? '
            'They will be notified and this cannot be undone.',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          Text(
            'Add a reason (optional)',
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kDeclineReasons.map((reason) {
              return WedChip(
                label: reason,
                isSelected: _selected == reason,
                // Tapping the selected chip again clears it — the reason is
                // optional, so it has to be possible to take one back.
                onTap: () => setState(
                    () => _selected = _selected == reason ? null : reason),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Keep it'),
        ),
        WedButton(
          label: 'Yes, decline',
          variant: WedButtonVariant.danger,
          shrinkWrap: true,
          height: 40,
          onPressed: () =>
              Navigator.pop(context, _selected ?? _kDefaultDeclineReason),
        ),
      ],
    );
  }
}
