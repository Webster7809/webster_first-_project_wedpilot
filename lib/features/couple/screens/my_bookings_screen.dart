import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/vendor_category_images.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/inquiry_status_display.dart';
import '../../../models/messaging.dart';
import '../../../providers/booking_provider.dart';
import '../../../widgets/booking_action_button.dart';
import '../../../widgets/wed_empty_state.dart';
import '../../../widgets/wed_skeleton.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('My Bookings'),
        centerTitle: true,
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
      ),
      body: bookingsAsync.when(
        loading: () => const WedListSkeleton(rows: 4, asCards: true, cardHeight: 140),
        error: (error, stack) => Center(
          child: Text(
            'Unable to load your bookings.',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
        ),
        data: (bookings) {
          if (bookings.isEmpty) {
            return WedEmptyState(
              icon: Icons.event_available_outlined,
              title: 'No bookings yet',
              message: 'Requests you send to vendors will show up here.',
              imageUrl: VendorCategoryImages.galleryFor('Photography')[0],
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(myBookingsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: bookings.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _BookingCard(inquiry: bookings[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final Inquiry inquiry;
  const _BookingCard({required this.inquiry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wording comes from the shared helper so a booking reads identically
    // here, on the vendor card and in the plan. This screen used to collapse
    // four distinct statuses into a single "Pending", which hid the most
    // reassuring signal a waiting couple has — whether the vendor has opened
    // the request at all.
    final display = InquiryStatusDisplay.of(inquiry.status);
    final statusLabel = display.label;
    final statusColor = display.color;
    final canRate = inquiry.status == InquiryStatus.booked &&
        inquiry.serviceDoneAt != null &&
        !inquiry.hasFeedback;
    final canCancel = InquiryStatusDisplay.isActive(inquiry.status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  inquiry.vendorName ?? 'Vendor',
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.forestGreen),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withAlpha(60)),
                ),
                child: Text(
                  statusLabel,
                  style: AppTextStyles.caption.copyWith(color: statusColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            inquiry.message,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (inquiry.weddingDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMM d, y').format(inquiry.weddingDate!),
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
          if (inquiry.status == InquiryStatus.declined && inquiry.declineReason != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.errorBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Reason: ${inquiry.declineReason}',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
              ),
            ),
          ],
          if (inquiry.status == InquiryStatus.booked && inquiry.hasFeedback) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.check_circle_outlined, size: 16, color: AppColors.success),
                const SizedBox(width: 6),
                Text("You've rated this vendor",
                    style: AppTextStyles.caption.copyWith(color: AppColors.success)),
              ],
            ),
          ],
          if (canRate) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    context.push(AppRoutes.coupleFeedbackNew, extra: inquiry.vendorId),
                icon: const Icon(Icons.rate_review_outlined, size: 16),
                label: const Text('Rate this vendor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
              ),
            ),
          ],
          if (canCancel) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => confirmAndCancelBooking(context, ref, inquiry),
                child: Text(
                  inquiry.status == InquiryStatus.booked ? 'Cancel booking' : 'Cancel request',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
