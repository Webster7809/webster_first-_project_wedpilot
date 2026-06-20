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
  int _step = 0;

  // Step 0
  final _businessNameCtrl = TextEditingController();
  String? _selectedCategory;

  // Step 1
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // Step 2
  final _locationCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final List<_ServiceItem> _services = [];

  // Step 3
  int _portfolioCount = 0;
  bool _saving = false;

  static const _stepTitles = [
    'Business basics',
    'About & contact',
    'Services & location',
    'Portfolio photos',
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

  bool get _canProceed {
    if (_step == 0) return _businessNameCtrl.text.trim().isNotEmpty && _selectedCategory != null;
    if (_step == 1) return _phoneCtrl.text.trim().isNotEmpty;
    if (_step == 2) return _locationCtrl.text.trim().isNotEmpty;
    return true;
  }

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  void _showAddServiceDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Add Service / Listing',
            style: AppTextStyles.titleMedium
                .copyWith(color: AppColors.forestGreen)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Service Name',
                labelStyle:
                    const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.forestGreen),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Starting Price (ZMW)',
                labelStyle:
                    const TextStyle(color: AppColors.textSecondary),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: AppColors.forestGreen),
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
              backgroundColor: AppColors.forestGreen,
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

  Future<void> _finish() async {
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
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          // ── Dark green header ──────────────────────────────────────────
          _OnboardingHeader(
            step: _step,
            totalSteps: _stepTitles.length,
            title: _stepTitles[_step],
            onBack: _step > 0 ? _back : null,
          ),

          // ── Step body ──────────────────────────────────────────────────
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: _buildStep(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _Step0(
          businessNameCtrl: _businessNameCtrl,
          selectedCategory: _selectedCategory,
          onCategorySelect: (c) => setState(() => _selectedCategory = c),
          canProceed: _canProceed,
          onNext: _next,
          onSkip: () => context.go('/vendor/dashboard'),
        );
      case 1:
        return _Step1(
          descCtrl: _descCtrl,
          phoneCtrl: _phoneCtrl,
          canProceed: _canProceed,
          onNext: _next,
        );
      case 2:
        return _Step2(
          locationCtrl: _locationCtrl,
          priceCtrl: _priceCtrl,
          services: _services,
          onAddService: _showAddServiceDialog,
          onRemoveService: (i) => setState(() => _services.removeAt(i)),
          canProceed: _canProceed,
          onNext: _next,
        );
      case 3:
        return _Step3(
          portfolioCount: _portfolioCount,
          onAdd: () => setState(() => _portfolioCount++),
          onRemove: () => setState(() => _portfolioCount--),
          saving: _saving,
          onFinish: _finish,
          onSkip: () => context.go('/vendor/dashboard'),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Shared header ──────────────────────────────────────────────────────────────

class _OnboardingHeader extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String title;
  final VoidCallback? onBack;

  const _OnboardingHeader({
    required this.step,
    required this.totalSteps,
    required this.title,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.forestGreen,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back / close row
              Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          size: 18, color: Colors.white),
                      onPressed: onBack,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  else
                    const SizedBox(width: 24),
                  const Spacer(),
                  Text(
                    'Step ${step + 1} of $totalSteps',
                    style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withAlpha(178)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'VENDOR ONBOARDING',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.amber,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (step + 1) / totalSteps,
                  backgroundColor: Colors.white.withAlpha(40),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.amber),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 0: Business basics ────────────────────────────────────────────────────

class _Step0 extends StatelessWidget {
  final TextEditingController businessNameCtrl;
  final String? selectedCategory;
  final ValueChanged<String> onCategorySelect;
  final bool canProceed;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  static const _categories = [
    'Venue', 'Catering', 'Photography', 'Decoration',
    'Entertainment', 'Transport', 'Music / DJ', 'Flowers',
    'Cake & Bakery', 'Makeup & Hair', 'Attire', 'Other',
  ];

  const _Step0({
    required this.businessNameCtrl,
    required this.selectedCategory,
    required this.onCategorySelect,
    required this.canProceed,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Logo upload
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.forestGreen.withAlpha(20),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.forestGreen.withAlpha(60),
                            width: 2),
                      ),
                      child: const Center(
                          child: Text('🏢',
                              style: TextStyle(fontSize: 36))),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text('Upload business logo',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 28),

              WedTextField(
                label: 'Business Name',
                hint: 'e.g. Mukuba Gardens',
                controller: businessNameCtrl,
                prefixIcon: Icons.business_outlined,
              ),
              const SizedBox(height: 24),

              Text('Service Category',
                  style: AppTextStyles.headlineSmall
                      .copyWith(color: AppColors.forestGreen)),
              const SizedBox(height: 6),
              Text(
                'Select the primary category that describes your business',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => onCategorySelect(cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.forestGreen
                            : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.forestGreen
                              : AppColors.divider,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color:
                                      AppColors.forestGreen.withAlpha(30),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : [],
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
              const SizedBox(height: 36),

              WedButton(
                label: 'Next',
                onPressed: canProceed ? onNext : null,
                icon: Icons.arrow_forward_rounded,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: onSkip,
                  child: Text('Skip for now',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Step 1: About & contact ────────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final TextEditingController descCtrl;
  final TextEditingController phoneCtrl;
  final bool canProceed;
  final VoidCallback onNext;

  const _Step1({
    required this.descCtrl,
    required this.phoneCtrl,
    required this.canProceed,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text('Tell couples about your business',
                  style: AppTextStyles.headlineSmall
                      .copyWith(color: AppColors.forestGreen)),
              const SizedBox(height: 16),
              WedTextField(
                label: 'Business Description',
                hint:
                    'What makes you special? Tell couples about your experience and style...',
                controller: descCtrl,
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              WedTextField(
                label: 'Phone Number',
                hint: '+260 9X XXX XXXX',
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone_outlined,
              ),
              const SizedBox(height: 36),
              WedButton(
                label: 'Next',
                onPressed: canProceed ? onNext : null,
                icon: Icons.arrow_forward_rounded,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Step 2: Services & location ────────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  final TextEditingController locationCtrl;
  final TextEditingController priceCtrl;
  final List<_ServiceItem> services;
  final VoidCallback onAddService;
  final ValueChanged<int> onRemoveService;
  final bool canProceed;
  final VoidCallback onNext;

  const _Step2({
    required this.locationCtrl,
    required this.priceCtrl,
    required this.services,
    required this.onAddService,
    required this.onRemoveService,
    required this.canProceed,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              WedTextField(
                label: 'Location / City',
                hint: 'e.g. Ndola, Copperbelt',
                controller: locationCtrl,
                prefixIcon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 16),
              WedTextField(
                label: 'Starting Price (ZMW)',
                hint: 'e.g. 15000',
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: Icons.payments_outlined,
              ),
              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Services & Listings',
                      style: AppTextStyles.headlineSmall
                          .copyWith(color: AppColors.forestGreen)),
                  TextButton.icon(
                    onPressed: onAddService,
                    icon: const Icon(Icons.add_circle_outline,
                        size: 18, color: AppColors.amber),
                    label: Text('Add',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: AppColors.amber)),
                  ),
                ],
              ),
              Text(
                'List the specific services or packages you offer',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),

              if (services.isEmpty)
                _EmptyListings()
              else
                ...services.asMap().entries.map(
                      (e) => _ServiceTile(
                        service: e.value,
                        onRemove: () => onRemoveService(e.key),
                      ),
                    ),
              const SizedBox(height: 36),

              WedButton(
                label: 'Next',
                onPressed: canProceed ? onNext : null,
                icon: Icons.arrow_forward_rounded,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Step 3: Portfolio ──────────────────────────────────────────────────────────

class _Step3 extends StatelessWidget {
  final int portfolioCount;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final bool saving;
  final VoidCallback onFinish;
  final VoidCallback onSkip;

  const _Step3({
    required this.portfolioCount,
    required this.onAdd,
    required this.onRemove,
    required this.saving,
    required this.onFinish,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text('Showcase your best work',
                  style: AppTextStyles.headlineSmall
                      .copyWith(color: AppColors.forestGreen)),
              const SizedBox(height: 6),
              Text(
                'Upload portfolio photos to attract more couples. You can add more later.',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                children: [
                  ...List.generate(
                    portfolioCount,
                    (i) => _PortfolioThumb(onRemove: onRemove),
                  ),
                  _AddPhotoTile(onTap: onAdd),
                ],
              ),
              const SizedBox(height: 36),

              WedButton(
                label: 'Finish Setup',
                onPressed: onFinish,
                isLoading: saving,
                icon: Icons.check_circle_outline,
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: onSkip,
                  child: Text('Skip for now',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ── Data ───────────────────────────────────────────────────────────────────────

class _ServiceItem {
  final String name;
  final String price;
  const _ServiceItem({required this.name, required this.price});
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _EmptyListings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(Icons.inventory_2_outlined,
              color: AppColors.textHint, size: 36),
          const SizedBox(height: 10),
          Text(
            'No listings yet.\nTap "Add" to create your first service.',
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary, height: 1.5),
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
        color: Colors.white,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.forestGreen.withAlpha(18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory_2_outlined,
                color: AppColors.forestGreen, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name,
                    style: AppTextStyles.titleMedium
                        .copyWith(color: AppColors.forestGreen)),
                if (service.price.isNotEmpty)
                  Text('From ZMW ${service.price}',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.textSecondary)),
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
        color: AppColors.forestGreen.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          const Center(
              child: Text('📷', style: TextStyle(fontSize: 26))),
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
                child:
                    const Icon(Icons.close, size: 13, color: Colors.white),
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
          color: Colors.white,
          border: Border.all(
              color: AppColors.divider,
              width: 1.5,
              style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_photo_alternate_outlined,
                color: AppColors.textHint, size: 28),
            const SizedBox(height: 4),
            Text('Add Photo',
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
