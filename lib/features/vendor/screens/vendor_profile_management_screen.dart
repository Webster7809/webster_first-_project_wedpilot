import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_text_field.dart';
import '../../../widgets/wed_snack_bar.dart';

class VendorProfileManagementScreen extends ConsumerStatefulWidget {
  const VendorProfileManagementScreen({super.key});

  @override
  ConsumerState<VendorProfileManagementScreen> createState() =>
      _VendorProfileManagementScreenState();
}

class _VendorProfileManagementScreenState
    extends ConsumerState<VendorProfileManagementScreen> {
  final _descCtrl = TextEditingController(text: 'Award-winning wedding photography studio');
  final _phoneCtrl = TextEditingController(text: '+1 (555) 123-4567');
  final _websiteCtrl = TextEditingController(text: 'www.blossomphotography.com');
  bool _saving = false;

  @override
  void dispose() {
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendor = ref.watch(vendorProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Manage Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo upload
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 90, height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: Text('📷', style: TextStyle(fontSize: 36))),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.edit, size: 14, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('Business Information', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            WedTextField(
              label: 'Business Name',
              controller: TextEditingController(text: vendor?.businessName ?? ''),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            WedTextField(
              label: 'Description',
              controller: _descCtrl,
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            WedTextField(
              label: 'Phone Number',
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
            ),
            const SizedBox(height: 16),
            WedTextField(
              label: 'Website',
              controller: _websiteCtrl,
              keyboardType: TextInputType.url,
              prefixIcon: Icons.language_outlined,
            ),
            const SizedBox(height: 24),

            Text('Portfolio', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              children: [
                ...List.generate(4, (i) => Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: Text('🌸', style: TextStyle(fontSize: 28))),
                )),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, color: AppColors.textSecondary),
                        SizedBox(height: 4),
                        Text('Add', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            WedButton(
              label: 'Save Changes',
              onPressed: () async {
                setState(() => _saving = true);
                await Future.delayed(const Duration(milliseconds: 600));
                if (mounted) {
                  setState(() => _saving = false);
                  showWedSnackBar(context, 'Profile updated successfully!', type: SnackType.success);
                }
              },
              isLoading: _saving,
            ),
          ],
        ),
      ),
    );
  }
}
