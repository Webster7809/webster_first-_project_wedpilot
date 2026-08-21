import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../core/services/vendor_api_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../core/utils/format_utils.dart';
import '../core/utils/inquiry_status_display.dart';
import '../models/messaging.dart';
import '../models/vendor_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/vendor_ai_provider.dart';
import 'wed_button.dart';
import 'wed_snack_bar.dart';

/// Shows a confirmation dialog, then cancels [inquiry] on confirm — shared by
/// [BookingActionButton] and the My Bookings list so both surfaces cancel the
/// exact same way and refresh from the exact same provider afterward.
///
/// Confirm and in-flight both live in the same dialog (mirroring the Delete
/// Account dialog in settings_screen.dart) rather than closing immediately on
/// "Yes, cancel" and leaving the underlying screen to catch up on its own:
/// that used to mean the booking card sat on stale data for a couple of
/// seconds with zero feedback, since myBookingsProvider only refetches once
/// the invalidate below resolves. Awaiting that refetch — not just firing
/// it — means every screen watching it already shows the new state by the
/// time this dialog closes.
Future<void> confirmAndCancelBooking(
  BuildContext context,
  WidgetRef ref,
  Inquiry inquiry,
) async {
  // Every call site gates this out once InquiryStatus.booked (self-serve
  // cancel goes away the moment a vendor approves — message them instead),
  // so this only ever runs for a request still awaiting an answer.
  bool submitting = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: const Text('Are you sure you want to cancel this booking request?'),
        actions: [
          TextButton(
            onPressed: submitting ? null : () => Navigator.of(dialogContext).pop(),
            child: const Text('Keep it'),
          ),
          WedButton(
            label: 'Yes, cancel',
            variant: WedButtonVariant.danger,
            isLoading: submitting,
            shrinkWrap: true,
            height: 40,
            onPressed: submitting
                ? null
                : () async {
                    setState(() => submitting = true);
                    final token = ref.read(authProvider.notifier).accessToken;
                    if (token == null) return;
                    try {
                      await VendorApiService.instance.cancelInquiry(token, inquiry.id);
                      ref.invalidate(myBookingsProvider);
                      await ref.read(myBookingsProvider.future);
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                      if (context.mounted) {
                        showWedSnackBar(context, 'Booking cancelled.', type: SnackType.info);
                      }
                    } on VendorApiException catch (e) {
                      setState(() => submitting = false);
                      if (dialogContext.mounted) {
                        showWedSnackBar(dialogContext, e.message, type: SnackType.error);
                      }
                    } catch (_) {
                      setState(() => submitting = false);
                      if (dialogContext.mounted) {
                        showWedSnackBar(
                          dialogContext,
                          'Could not cancel this booking. Please try again.',
                          type: SnackType.error,
                        );
                      }
                    }
                  },
          ),
        ],
      ),
    ),
  );
}

/// Reflects the couple's actual request state for [vendor] instead of always
/// showing "Book this vendor" — a sent request shows as pending, and once the
/// vendor accepts it flips to approved, so the couple never sees a stale
/// "book" button for a vendor they already booked.
///
/// Booking is a single tap. There is no form: the wedding date, guest count
/// and budget the couple already entered are sent automatically, so the only
/// thing the old sheet ever asked for — a free-text message restating all
/// three — is composed here instead. A mis-tap stays recoverable through the
/// Undo action on the confirmation snackbar.
class BookingActionButton extends ConsumerStatefulWidget {
  final VendorProfile vendor;
  final double height;

  const BookingActionButton({
    super.key,
    required this.vendor,
    this.height = 42,
  });

  @override
  ConsumerState<BookingActionButton> createState() =>
      _BookingActionButtonState();
}

class _BookingActionButtonState extends ConsumerState<BookingActionButton> {
  bool _sending = false;

  /// What the vendor receives as the request body. Built from what the couple
  /// already told the app rather than asking for it again — the vendor gets
  /// strictly more than the old free-text box usually carried, and the couple
  /// types nothing. Missing pieces are simply omitted.
  String _composeMessage({
    DateTime? weddingDate,
    int? guests,
    double? budget,
  }) {
    final parts = <String>[
      if (weddingDate != null)
        'Wedding on ${DateFormat('d MMM y').format(weddingDate)}',
      if (guests != null && guests > 0) '$guests guests',
      if (budget != null && budget > 0) 'Budget ${fmtCurrency(budget)}',
    ];
    final opener = parts.isEmpty
        ? "Hi — we'd like to book you for our wedding."
        : '${parts.join(' · ')}.';
    final category = widget.vendor.category;
    return category.isEmpty
        ? opener
        : "$opener We're interested in your $category services.";
  }

  Future<void> _send() async {
    final token = ref.read(authProvider.notifier).accessToken;
    if (token == null) {
      showWedSnackBar(context, 'Please sign in to book a vendor.',
          type: SnackType.error);
      return;
    }

    final profile = ref.read(coupleProfileProvider);
    final wizardBudget = ref.read(wizardBudgetProvider);
    final wizardGuests = ref.read(wizardGuestCountProvider);
    final savedBudget = ref.read(budgetProvider).data;

    final weddingDate = profile?.weddingDate;
    final guests = (wizardGuests != null && wizardGuests > 0)
        ? wizardGuests
        : profile?.guestCount;
    final budget = (wizardBudget != null && wizardBudget > 0)
        ? wizardBudget
        : savedBudget?.totalAmount ?? profile?.totalBudget;

    setState(() => _sending = true);
    try {
      final inquiry = await VendorApiService.instance.sendInquiry(
        token,
        widget.vendor.id,
        message: _composeMessage(
          weddingDate: weddingDate,
          guests: guests,
          budget: budget,
        ),
        // Passed through rather than dropped, so the vendor's inbox shows a
        // real budget and date instead of a permanently empty pill.
        budgetRangeMin: budget,
        budgetRangeMax: budget,
        weddingDate: weddingDate,
      );
      // The refresh that makes this button, My Bookings and the plan's locked
      // categories agree immediately. Without it the button keeps reading
      // "Book this vendor" and a second tap creates a duplicate request.
      ref.invalidate(myBookingsProvider);
      if (!mounted) return;
      setState(() => _sending = false);
      showWedSnackBar(
        context,
        'Request sent to ${widget.vendor.businessName}.',
        type: SnackType.success,
        actionLabel: 'UNDO',
        onAction: () => _undo(inquiry),
      );
    } on VendorApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      showWedSnackBar(context, e.message, type: SnackType.error);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      showWedSnackBar(context, 'Could not send your request. Please try again.',
          type: SnackType.error);
    }
  }

  /// Straight cancel of the request just created — no confirmation dialog,
  /// because the couple is undoing their own action from a second ago rather
  /// than abandoning a booking they'd been waiting on.
  Future<void> _undo(Inquiry inquiry) async {
    final token = ref.read(authProvider.notifier).accessToken;
    if (token == null) return;
    try {
      await VendorApiService.instance.cancelInquiry(token, inquiry.id);
      ref.invalidate(myBookingsProvider);
      if (mounted) {
        showWedSnackBar(context, 'Request withdrawn.', type: SnackType.info);
      }
    } catch (_) {
      if (mounted) {
        showWedSnackBar(context, 'Could not undo — check My Bookings.',
            type: SnackType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookings =
        ref.watch(myBookingsProvider).valueOrNull ?? const <Inquiry>[];
    final mine = bookings.where((b) => b.vendorId == widget.vendor.id).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    // Most recent request only — a past decline shouldn't block booking again.
    final latest = mine.firstOrNull;

    // Declined *and* cancelled both free the vendor up to be booked again.
    // Leaving cancelled out used to strand this on "Booking requested" forever,
    // with a Cancel action the server rejected as already closed.
    if (latest == null || !InquiryStatusDisplay.isActive(latest.status)) {
      return SizedBox(
        width: double.infinity,
        child: WedButton(
          label: 'Book this vendor',
          variant: WedButtonVariant.accent,
          height: widget.height,
          isLoading: _sending,
          onPressed: _sending ? null : _send,
        ),
      );
    }

    final display = InquiryStatusDisplay.of(latest.status);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusPill(
          icon: display.icon,
          label: display.label,
          color: display.color,
          height: widget.height,
        ),
        // Once the vendor has approved, self-serve cancel goes away — backing
        // out of a confirmed booking isn't the same one-tap action as
        // withdrawing a request still awaiting an answer; message the vendor
        // instead (see the new "Message" entry point on this same screen).
        if (latest.status != InquiryStatus.booked)
          TextButton(
            onPressed: () => confirmAndCancelBooking(context, ref, latest),
            child: Text(
              'Cancel request',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double height;

  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
