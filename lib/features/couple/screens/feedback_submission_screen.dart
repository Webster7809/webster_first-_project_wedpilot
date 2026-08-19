import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/vendor_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/vendor_feedback.dart';
import '../../../models/vendor_profile.dart';
import '../../../widgets/highlighted_text.dart';
import '../../../widgets/typeahead_field.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_text_field.dart';
import '../../../widgets/wed_snack_bar.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/vendor_provider.dart';
import '../../../core/services/api_error.dart';

/// Private post-booking feedback — a star rating plus an optional comment.
/// Never shown to other couples; only aggregate CRS/badges derived from it
/// are public (see VendorProfile's badge fields).
class FeedbackSubmissionScreen extends ConsumerStatefulWidget {
  final String? initialVendorId;
  const FeedbackSubmissionScreen({super.key, this.initialVendorId});

  @override
  ConsumerState<FeedbackSubmissionScreen> createState() => _FeedbackSubmissionScreenState();
}

class _FeedbackSubmissionScreenState extends ConsumerState<FeedbackSubmissionScreen> {
  int _rating = 5;
  OnTimeAnswer? _onTime;
  final _commentCtrl = TextEditingController();
  final _vendorSearchCtrl = TextEditingController();
  VendorProfile? _selectedVendor;
  bool _submitting = false;
  bool _resolvedInitialVendor = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _vendorSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedVendor == null) {
      showWedSnackBar(context, 'Please select a vendor', type: SnackType.warning);
      return;
    }
    final token = ref.read(authProvider.notifier).accessToken;
    if (token == null) {
      showWedSnackBar(context, 'Not signed in.', type: SnackType.error);
      return;
    }

    setState(() => _submitting = true);
    try {
      await VendorApiService.instance.submitFeedback(
        token,
        _selectedVendor!.id,
        starRating: _rating,
        comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
        onTime: _onTime,
      );
      ref.invalidate(myBookingsProvider);
      if (!mounted) return;
      showWedSnackBar(context, 'Thanks for your feedback!', type: SnackType.success);
      context.pop();
    } on VendorApiException catch (e) {
      if (!mounted) return;
      showWedSnackBar(context, e.message, type: SnackType.error);
    } catch (e) {
      if (!mounted) return;
      showWedSnackBar(context, describeError(e), type: SnackType.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Resolve a pre-selected vendor (e.g. arriving from "Rate this vendor" on
    // a vendor profile) the first time this vendor's detail is available.
    if (widget.initialVendorId != null && !_resolvedInitialVendor) {
      final detail = ref.watch(vendorDetailProvider(widget.initialVendorId!));
      detail.whenData((v) {
        if (!_resolvedInitialVendor) {
          _resolvedInitialVendor = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _vendorSearchCtrl.text = v.businessName;
            setState(() => _selectedVendor = v);
          });
        }
      });
    }

    final vendorsAsync = ref.watch(rateableVendorsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Rate Your Vendor')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth >= 600;
          final maxWidth = isTablet ? 500.0 : double.infinity;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.info.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.lock_outlined, color: AppColors.info, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Your feedback is private. Your written comments are never shown '
                              'publicly — only your star rating contributes to this vendor\'s '
                              'public score.',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    Text('Select Vendor', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    // Every vendor who's accepted a booking and marked the
                    // service done lands here automatically — no need to
                    // remember a name and type it into search first. The
                    // typical case is one or two vendors, so a plain tappable
                    // list beats making that the couple's job to discover.
                    if (vendorsAsync.hasValue && (vendorsAsync.value ?? const []).isNotEmpty) ...[
                      ...vendorsAsync.value!.map((v) {
                        final isSelected = _selectedVendor?.id == v.id;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: isSelected
                                ? AppColors.secondary.withAlpha(30)
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => setState(() {
                                _selectedVendor = v;
                                _vendorSearchCtrl.text = v.businessName;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected ? AppColors.secondary : AppColors.divider,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppColors.creamDark,
                                      backgroundImage: v.logoUrl != null
                                          ? NetworkImage(resolveMediaUrl(v.logoUrl!))
                                          : null,
                                      onBackgroundImageError: v.logoUrl != null ? (_, _) {} : null,
                                      child: v.logoUrl == null
                                          ? Text(v.businessName.isNotEmpty
                                              ? v.businessName[0].toUpperCase()
                                              : '?')
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            v.businessName,
                                            style: AppTextStyles.bodyMedium,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            v.category,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(color: AppColors.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(Icons.check_circle,
                                          color: AppColors.secondary, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 4),
                      Text(
                        'Or search for a different vendor:',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                    ],
                    TypeaheadField<VendorProfile>(
                      hint: "Search a vendor you've booked...",
                      controller: _vendorSearchCtrl,
                      prefixIcon: Icons.search,
                      suggestionsCallback: (query) {
                        final vendors = vendorsAsync.valueOrNull ?? const <VendorProfile>[];
                        if (query.isEmpty) return vendors;
                        final q = query.toLowerCase();
                        return vendors.where((v) => v.businessName.toLowerCase().contains(q)).toList();
                      },
                      displayStringForOption: (v) => v.businessName,
                      onSelected: (v) => setState(() => _selectedVendor = v),
                      itemBuilder: (context, v, query, isHighlighted) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.creamDark,
                              backgroundImage:
                                  v.logoUrl != null ? NetworkImage(resolveMediaUrl(v.logoUrl!)) : null,
                              onBackgroundImageError: v.logoUrl != null ? (_, _) {} : null,
                              child: v.logoUrl == null
                                  ? Text(v.businessName.isNotEmpty ? v.businessName[0].toUpperCase() : '?')
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  HighlightedText(
                                    text: v.businessName,
                                    query: query,
                                    style: AppTextStyles.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    v.category,
                                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (vendorsAsync.hasValue && (vendorsAsync.value ?? const []).isEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'No vendors ready to rate yet — a vendor shows up here once '
                        "they've marked your booking's service as complete.",
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                    if (_selectedVendor != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Rating ${_selectedVendor!.businessName} · ${_selectedVendor!.category}',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),

                    Text('Your Rating', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Tap a star to set your rating.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (i) {
                        final filled = i < _rating;
                        // Plain IconButton — the same widget rate_vendor_prompt.dart's
                        // quick-rate popup already uses successfully. The
                        // previous Material(shape: CircleBorder(), clipBehavior:
                        // Clip.antiAlias) + InkWell combination visually
                        // rendered fine but silently ate every tap: its hit
                        // region never actually matched the drawn icon.
                        return IconButton(
                          onPressed: () => setState(() => _rating = i + 1),
                          icon: Icon(
                            filled ? Icons.star : Icons.star_outlined,
                            color: filled
                                ? AppColors.goldPremium
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 32,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_rating of 5 stars',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text('Did the vendor arrive on time?', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SegmentedButton<OnTimeAnswer>(
                            segments: const [
                              ButtonSegment(value: OnTimeAnswer.yes, label: Text('Yes')),
                              ButtonSegment(value: OnTimeAnswer.no, label: Text('No')),
                              ButtonSegment(value: OnTimeAnswer.notApplicable, label: Text('N/A')),
                            ],
                            selected: _onTime == null ? const {} : {_onTime!},
                            emptySelectionAllowed: true,
                            onSelectionChanged: (selection) => setState(
                              () => _onTime = selection.isEmpty ? null : selection.first,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    WedTextField(
                      label: 'Comment (optional)',
                      hint: 'Share details about your experience working with this vendor...',
                      controller: _commentCtrl,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 32),
                    WedButton(label: 'Submit Feedback', onPressed: _submit, isLoading: _submitting),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
