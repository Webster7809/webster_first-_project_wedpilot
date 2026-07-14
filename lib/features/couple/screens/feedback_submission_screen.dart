import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/vendor_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/vendor_feedback.dart';
import '../../../models/vendor_profile.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_text_field.dart';
import '../../../widgets/wed_snack_bar.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/vendor_provider.dart';

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
  VendorProfile? _selectedVendor;
  bool _submitting = false;
  bool _resolvedInitialVendor = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
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
    } catch (_) {
      if (!mounted) return;
      showWedSnackBar(context, 'Could not reach the server. Please try again.', type: SnackType.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickVendor() async {
    final selected = await showModalBottomSheet<VendorProfile>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _VendorPickerSheet(),
    );
    if (selected != null) {
      setState(() => _selectedVendor = selected);
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
            if (mounted) setState(() => _selectedVendor = v);
          });
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
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
                          const Icon(Icons.lock_outline_rounded, color: AppColors.info, size: 18),
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
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _pickVendor,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedVendor?.businessName ?? 'Choose a vendor you\'ve booked',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: _selectedVendor == null
                                    ? AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint)
                                    : AppTextStyles.bodyMedium,
                              ),
                            ),
                            const Icon(Icons.expand_more, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    Text('Your Rating', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (i) => Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => setState(() => _rating = i + 1),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              i < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                              color: AppColors.goldPremium,
                              size: 36,
                            ),
                          ),
                        ),
                      )),
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

class _VendorPickerSheet extends ConsumerStatefulWidget {
  const _VendorPickerSheet();

  @override
  ConsumerState<_VendorPickerSheet> createState() => _VendorPickerSheetState();
}

class _VendorPickerSheetState extends ConsumerState<_VendorPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(rateableVendorsProvider);

    // The sheet is deliberately height-filled (the Expanded list needs a
    // bounded height to scroll), unlike this app's other content-sized
    // sheets — so unlike them it must subtract the keyboard inset itself,
    // or the search field's keyboard would push it past the screen edge.
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85 - viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight.clamp(280.0, double.infinity)),
        child: Material(
          color: AppColors.background,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Column(
          children: [
            const SizedBox(height: 12),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text('Select Vendor', style: AppTextStyles.headlineSmall),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: WedTextField(
                hint: 'Search vendors...',
                controller: _searchCtrl,
                prefixIcon: Icons.search,
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: vendorsAsync.when(
                data: (vendors) {
                  if (vendors.isEmpty) {
                    return _buildMessage(
                      'No vendors ready to rate yet — a vendor shows up here once '
                      "they've marked your booking's service as complete.",
                    );
                  }
                  final filtered = _query.isEmpty
                      ? vendors
                      : vendors
                          .where((v) => v.businessName.toLowerCase().contains(_query))
                          .toList();
                  if (filtered.isEmpty) {
                    return _buildMessage('No vendors match "$_query".');
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (context, i) {
                      final v = filtered[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.creamDark,
                          backgroundImage: v.logoUrl != null
                              ? NetworkImage(resolveMediaUrl(v.logoUrl!))
                              : null,
                          onBackgroundImageError: v.logoUrl != null ? (_, _) {} : null,
                          child: v.logoUrl == null
                              ? Text(v.businessName.isNotEmpty ? v.businessName[0].toUpperCase() : '?')
                              : null,
                        ),
                        title: Text(v.businessName, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(v.category, maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => Navigator.pop(context, v),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _buildMessage('Could not load vendors. Please try again.'),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(String message) => Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
}
