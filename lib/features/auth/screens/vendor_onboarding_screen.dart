import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_text_field.dart';
import '../../../widgets/wed_snack_bar.dart';

class VendorOnboardingScreen extends ConsumerStatefulWidget {
  const VendorOnboardingScreen({super.key});

  @override
  ConsumerState<VendorOnboardingScreen> createState() =>
      _VendorOnboardingScreenState();
}

class _VendorOnboardingScreenState
    extends ConsumerState<VendorOnboardingScreen> {
  final _businessNameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  String? _selectedCategory;
  final List<_ServiceItem> _services = [];
  int _portfolioCount = 0;
  bool _saving = false;

  static const _categories = [
    'Photography',
    'Catering',
    'Decoration',
    'Venue',
    'Entertainment',
    'Attire',
    'Transport',
    'Music / DJ',
    'Flowers',
    'Cake & Bakery',
    'Makeup & Hair',
    'Other',
  ];

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _showAddServiceDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Service / Listing',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Service Name',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.secondary),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Starting Price (K)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.secondary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() => _services.add(_ServiceItem(
                      name: nameCtrl.text.trim(),
                      price: priceCtrl.text.trim(),
                    )));
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Add Listing'),
          ),
        ],
      ),
    );
  }

  Future<void> _finishSetup() async {
    setState(() => _saving = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _saving = false);
      showWedSnackBar(
        context,
        'Profile created! Welcome to Wedpilot.',
        type: SnackType.success,
      );
      context.go('/vendor/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 170,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.secondary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.secondary, Color(0xFFAD1457)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: const [
                        Text(
                          '🏢 Set Up Your Business',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Create your listings and showcase your work to attract couples.',
                          style: TextStyle(
                            color: Color(0xFFFFCDD2),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Logo ───────────────────────────────────────
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                            child: Text('📷',
                                style: TextStyle(fontSize: 40))),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Upload Business Logo',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Business Details ───────────────────────────
                Text('Business Details',
                    style: AppTextStyles.headlineSmall),
                const SizedBox(height: 16),
                WedTextField(
                  label: 'Business Name',
                  hint: 'e.g. Blossom Photography',
                  controller: _businessNameCtrl,
                  prefixIcon: Icons.business_outlined,
                ),
                const SizedBox(height: 16),
                WedTextField(
                  label: 'Description',
                  hint:
                      'Tell couples about your services and what makes you special...',
                  controller: _descCtrl,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                WedTextField(
                  label: 'Phone Number',
                  hint: '+260 9X XXX XXXX',
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                ),
                const SizedBox(height: 16),
                WedTextField(
                  label: 'Location / City',
                  hint: 'e.g. Lusaka',
                  controller: _locationCtrl,
                  prefixIcon: Icons.location_on_outlined,
                ),
                const SizedBox(height: 28),

                // ── Category ───────────────────────────────────
                Text('Service Category',
                    style: AppTextStyles.headlineSmall),
                const SizedBox(height: 6),
                const Text(
                  'Select the primary category that describes your business',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.secondary
                              : AppColors.surface,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.secondary
                                : AppColors.divider,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // ── Services / Listings ────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Services & Listings',
                        style: AppTextStyles.headlineSmall),
                    TextButton.icon(
                      onPressed: _showAddServiceDialog,
                      icon: const Icon(Icons.add_circle_outline,
                          size: 18, color: AppColors.secondary),
                      label: const Text('Add',
                          style: TextStyle(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'List the specific services or packages you offer',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                if (_services.isEmpty)
                  _EmptyListings()
                else
                  ..._services.asMap().entries.map(
                        (e) => _ServiceTile(
                          service: e.value,
                          onRemove: () =>
                              setState(() => _services.removeAt(e.key)),
                        ),
                      ),
                const SizedBox(height: 28),

                // ── Portfolio Photos ───────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Portfolio Photos',
                        style: AppTextStyles.headlineSmall),
                    Text(
                      '$_portfolioCount photo${_portfolioCount == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Upload your best work to attract more couples',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  children: [
                    ...List.generate(
                      _portfolioCount,
                      (i) => _PortfolioThumb(
                        onRemove: () =>
                            setState(() => _portfolioCount--),
                      ),
                    ),
                    _AddPhotoTile(
                        onTap: () =>
                            setState(() => _portfolioCount++)),
                  ],
                ),
                const SizedBox(height: 36),

                // ── Finish ─────────────────────────────────────
                WedButton(
                  label: 'Finish Setup',
                  onPressed: _finishSetup,
                  isLoading: _saving,
                  icon: Icons.check_circle_outline,
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/vendor/dashboard'),
                    child: const Text(
                      'Skip for now',
                      style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceItem {
  final String name;
  final String price;
  const _ServiceItem({required this.name, required this.price});
}

class _EmptyListings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined,
              color: AppColors.textHint, size: 36),
          SizedBox(height: 10),
          Text(
            'No listings yet.\nTap "Add" to create your first service.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final _ServiceItem service;
  final VoidCallback onRemove;

  const _ServiceTile({required this.service, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.inventory_2_outlined,
              color: AppColors.tertiary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 14),
                ),
                if (service.price.isNotEmpty)
                  Text(
                    'From K${service.price}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: AppColors.error, size: 20),
            onPressed: onRemove,
            tooltip: 'Remove listing',
          ),
        ],
      ),
    );
  }
}

class _PortfolioThumb extends StatelessWidget {
  final VoidCallback onRemove;
  const _PortfolioThumb({required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          const Center(
              child: Text('🌸', style: TextStyle(fontSize: 28))),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                    color: AppColors.error, shape: BoxShape.circle),
                child: const Icon(Icons.close,
                    size: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPhotoTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined,
                color: AppColors.textSecondary, size: 28),
            SizedBox(height: 4),
            Text(
              'Add Photo',
              style:
                  TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
