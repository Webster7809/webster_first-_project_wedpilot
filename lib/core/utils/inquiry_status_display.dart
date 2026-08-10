import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../models/messaging.dart';

/// How a booking's status is worded and coloured for the **couple**.
///
/// Exists because the same state used to read three different ways depending
/// on where you looked — "Booking requested — awaiting approval" on a vendor
/// card, "Pending" in My Bookings, "Booked" in the vendor's own inbox. Worse,
/// My Bookings collapsed four distinct backend statuses into a single
/// "Pending", so a couple could not tell whether the vendor had even opened
/// the request. Keeping the wording in one place is what makes the answer to
/// "what's happening with this booking?" the same everywhere.
///
/// Vendor-facing wording deliberately lives elsewhere: the same row means
/// something different to the business receiving it.
class InquiryStatusDisplay {
  final String label;
  final Color color;
  final IconData icon;

  const InquiryStatusDisplay._(this.label, this.color, this.icon);

  factory InquiryStatusDisplay.of(InquiryStatus status) {
    switch (status) {
      case InquiryStatus.booked:
        return const InquiryStatusDisplay._(
            'Booking approved', AppColors.success, Icons.check_circle);
      case InquiryStatus.declined:
        return const InquiryStatusDisplay._(
            'Declined', AppColors.error, Icons.cancel_outlined);
      case InquiryStatus.cancelled:
        return const InquiryStatusDisplay._(
            'Cancelled', AppColors.textSecondary, Icons.block_outlined);
      case InquiryStatus.viewed:
        // Worth distinguishing from newInquiry: "the vendor has seen it" is
        // the single most reassuring thing a waiting couple can be told, and
        // it was previously hidden behind a generic "Pending".
        return const InquiryStatusDisplay._(
            'Seen by vendor', AppColors.amber, Icons.visibility_outlined);
      case InquiryStatus.responded:
      case InquiryStatus.quoted:
        return const InquiryStatusDisplay._(
            'Vendor replied', AppColors.amber, Icons.mark_email_read_outlined);
      case InquiryStatus.newInquiry:
        return const InquiryStatusDisplay._(
            'Awaiting approval', AppColors.amber, Icons.hourglass_top);
    }
  }

  /// Whether this booking is still live — i.e. the couple is committed to this
  /// vendor and the plan should treat the category as settled rather than
  /// re-deciding it. Declined and cancelled requests are finished, so they
  /// free the vendor up to be matched again.
  static bool isActive(InquiryStatus status) =>
      status != InquiryStatus.declined && status != InquiryStatus.cancelled;
}
