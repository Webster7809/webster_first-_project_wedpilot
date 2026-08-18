import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/router/app_routes.dart';
import '../core/services/vendor_api_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/vendor_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_provider.dart';
import 'vendor_hero_image.dart';
import 'wed_button.dart';
import 'wed_snack_bar.dart';
import '../core/services/api_error.dart';

/// Opens automatically once a booking's service is marked done — not
/// something the couple has to go hunting for. Deliberately just a star tap
/// and a submit button, nothing else required: the full multi-field form
/// (comment, on-time) is still there via "Add more detail" for anyone who
/// wants to say more, but the fast path is one tap.
Future<void> showRateVendorPrompt(
  BuildContext context,
  WidgetRef ref,
  VendorProfile vendor,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _RateVendorSheet(vendor: vendor),
  );
}

class _RateVendorSheet extends ConsumerStatefulWidget {
  final VendorProfile vendor;
  const _RateVendorSheet({required this.vendor});

  @override
  ConsumerState<_RateVendorSheet> createState() => _RateVendorSheetState();
}

class _RateVendorSheetState extends ConsumerState<_RateVendorSheet> {
  int _rating = 0;
  bool _submitting = false;

  Future<void> _submit() async {
    if (_rating == 0) return;
    final token = ref.read(authProvider.notifier).accessToken;
    if (token == null) return;

    setState(() => _submitting = true);
    try {
      await VendorApiService.instance.submitFeedback(
        token,
        widget.vendor.id,
        starRating: _rating,
      );
      ref.invalidate(myBookingsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showWedSnackBar(context, 'Thanks for rating ${widget.vendor.businessName}!',
          type: SnackType.success);
    } on VendorApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showWedSnackBar(context, e.message, type: SnackType.error);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showWedSnackBar(context, describeError(e),
          type: SnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withAlpha(60),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 64,
                height: 64,
                child: VendorHeroImage(
                  vendor: widget.vendor,
                  height: 64,
                  memCacheWidth: 200,
                  single: true,
                  showBadge: false,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'How was ${widget.vendor.businessName}?',
              style: AppTextStyles.headlineSmall.copyWith(color: colors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Your booking is complete — a quick rating helps other couples.',
              style: AppTextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final filled = i < _rating;
                return IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                    filled ? Icons.star : Icons.star_border,
                    color: filled ? AppColors.goldDeep : colors.onSurfaceVariant,
                    size: 36,
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),
            WedButton(
              label: 'Submit rating',
              onPressed: _rating == 0 ? null : _submit,
              isLoading: _submitting,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _submitting
                  ? null
                  : () {
                      Navigator.of(context).pop();
                      context.push(AppRoutes.coupleFeedbackNew,
                          extra: widget.vendor.id);
                    },
              child: const Text('Add more detail instead'),
            ),
            TextButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(),
              child: Text('Maybe later',
                  style: TextStyle(color: colors.onSurfaceVariant)),
            ),
          ],
        ),
      ),
    );
  }
}
