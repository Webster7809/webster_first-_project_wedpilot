import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_snack_bar.dart';

class VendorVerificationScreen extends StatefulWidget {
  const VendorVerificationScreen({super.key});

  @override
  State<VendorVerificationScreen> createState() => _VendorVerificationScreenState();
}

class _VendorVerificationScreenState extends State<VendorVerificationScreen> {
  final _pendingVendors = [
    {'name': 'Sunrise Events', 'category': 'Venue', 'submitted': '2 days ago', 'docs': 3},
    {'name': 'Harmony Strings Band', 'category': 'Music', 'submitted': '3 days ago', 'docs': 2},
    {'name': 'Petal Dreams Floristry', 'category': 'Floristry', 'submitted': '5 days ago', 'docs': 4},
    {'name': 'Cake by Sofia', 'category': 'Cake', 'submitted': '1 week ago', 'docs': 2},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Vendor Verification Queue')),
      body: _pendingVendors.isEmpty
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('✅', style: TextStyle(fontSize: 56)),
                SizedBox(height: 12),
                Text('All caught up!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ],
            ))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _pendingVendors.length,
              itemBuilder: (_, i) {
                final vendor = _pendingVendors[i];
                return _VerificationCard(
                  vendor: vendor,
                  onApprove: () {
                    setState(() => _pendingVendors.removeAt(i));
                    showWedSnackBar(context, '${vendor['name']} approved!', type: SnackType.success);
                  },
                  onReject: () {
                    setState(() => _pendingVendors.removeAt(i));
                    showWedSnackBar(context, '${vendor['name']} rejected.', type: SnackType.error);
                  },
                );
              },
            ),
    );
  }
}

class _VerificationCard extends StatelessWidget {
  final Map<String, dynamic> vendor;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _VerificationCard({required this.vendor, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vendor['name'] as String, style: AppTextStyles.headlineSmall),
                      Text('${vendor['category']} · Submitted ${vendor['submitted']}',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withAlpha(31),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('Pending',
                      style: AppTextStyles.caption.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.description_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('${vendor['docs']} documents submitted',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: WedButton(
                    label: 'Reject',
                    variant: WedButtonVariant.destructive,
                    onPressed: onReject,
                    height: 40,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: WedButton(
                    label: 'Approve',
                    onPressed: onApprove,
                    height: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
