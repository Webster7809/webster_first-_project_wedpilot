import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_text_field.dart';
import '../../../widgets/wed_snack_bar.dart';

class ReviewSubmissionScreen extends ConsumerStatefulWidget {
  const ReviewSubmissionScreen({super.key});

  @override
  ConsumerState<ReviewSubmissionScreen> createState() => _ReviewSubmissionScreenState();
}

class _ReviewSubmissionScreenState extends ConsumerState<ReviewSubmissionScreen> {
  int _rating = 5;
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String? _selectedVendorId;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedVendorId == null) {
      showWedSnackBar(context, 'Please select a vendor', type: SnackType.warning);
      return;
    }
    if (_titleCtrl.text.isEmpty || _bodyCtrl.text.isEmpty) {
      showWedSnackBar(context, 'Please fill in all fields', type: SnackType.warning);
      return;
    }
    setState(() => _submitting = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      showWedSnackBar(context, 'Review submitted! It will appear after moderation.', type: SnackType.success);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Write a Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.info, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Reviews are available after your wedding date.',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.info)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Select Vendor', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedVendorId,
              hint: const Text('Choose a vendor you worked with'),
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: const [
                DropdownMenuItem(value: 'v-001', child: Text('Blossom Photography')),
                DropdownMenuItem(value: 'v-003', child: Text('The Garden Venue')),
                DropdownMenuItem(value: 'v-004', child: Text('Culinary Bliss Catering')),
              ],
              onChanged: (v) => setState(() => _selectedVendorId = v),
            ),
            const SizedBox(height: 20),

            Text('Your Rating', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) => GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    i < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: AppColors.goldPremium,
                    size: 36,
                  ),
                ),
              )),
            ),
            const SizedBox(height: 20),

            WedTextField(
              label: 'Review Title',
              hint: 'Summarize your experience',
              controller: _titleCtrl,
            ),
            const SizedBox(height: 16),
            WedTextField(
              label: 'Your Review',
              hint: 'Share details about your experience working with this vendor...',
              controller: _bodyCtrl,
              maxLines: 5,
            ),
            const SizedBox(height: 16),

            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Add Photos (up to 5)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.divider),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
            const SizedBox(height: 32),
            WedButton(label: 'Submit Review', onPressed: _submit, isLoading: _submitting),
          ],
        ),
      ),
    );
  }
}
