import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wizard_widgets.dart';
import '../../../providers/auth_provider.dart';

class VendorOnboardingScreen extends ConsumerStatefulWidget {
  const VendorOnboardingScreen({super.key});

  @override
  ConsumerState<VendorOnboardingScreen> createState() =>
      _VendorOnboardingScreenState();
}

class _VendorOnboardingScreenState
    extends ConsumerState<VendorOnboardingScreen> {
  int _step = 0;
  static const int _totalSteps = 4;

  // Step 0 — Category & location
  String? _selectedCategory;
  final _locationCtrl = TextEditingController();

  // Step 1 — Portfolio
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _picker = ImagePicker();
  Uint8List? _coverPhotoBytes;
  final List<Uint8List> _galleryBytes = [];

  // Step 2 — Contact
  final _phoneCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();

  static const _stepLabels = [
    'TELL US ABOUT YOUR BUSINESS',
    'SHOWCASE YOUR WORK',
    'HOW SHOULD COUPLES REACH YOU',
    'ALMOST THERE',
  ];

  static const _stepTitles = [
    'What service do\nyou offer couples?',
    'Build your\nportfolio listing',
    'Add your\ncontact details',
    'Your listing is\nunder review',
  ];

  static const _categories = [
    ('Venue', Icons.grid_view_rounded),
    ('Catering', Icons.restaurant_outlined),
    ('Photography', Icons.camera_alt_outlined),
    ('Decor & flowers', Icons.local_florist_outlined),
    ('DJ & MC', Icons.music_note_outlined),
    ('Transport', Icons.local_shipping_outlined),
    ('Wedding attire', Icons.checkroom_outlined),
    ('Cake & sweets', Icons.cake_outlined),
  ];

  @override
  void dispose() {
    _locationCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _instagramCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    }
  }

  Future<void> _pickCoverPhoto() async {
    final file = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    setState(() => _coverPhotoBytes = bytes);
  }

  Future<void> _addGalleryPhoto() async {
    if (_galleryBytes.length >= 6) return;
    final file = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    setState(() => _galleryBytes.add(bytes));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Column(
          children: [
            WizardHeader(
              step: _step,
              totalSteps: _totalSteps,
              stepLabel: _stepLabels[_step],
              stepTitle: _stepTitles[_step],
              onBack: _step > 0 && _step < 3
                  ? () => setState(() => _step--)
                  : null,
            ),
            Expanded(
              child: _step == 3
                  ? _buildConfirmationStep()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: _buildStep(),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildCategoryStep();
      case 1:
        return _buildPortfolioStep();
      case 2:
        return _buildContactStep();
      default:
        return const SizedBox();
    }
  }

  // ── Step 0: Category & location ─────────────────────────────────────────────

  Widget _buildCategoryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WizardSectionLabel(icon: Icons.grid_view_outlined, label: 'Vendor category'),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _categories.map((cat) {
            final (name, icon) = cat;
            final isSelected = _selectedCategory == name;
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.amber.withAlpha(30) : AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.amber : AppColors.divider,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.amber
                            : AppColors.creamDark,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 22,
                        color: isSelected ? Colors.white : AppColors.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.amber
                            : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        WizardSectionLabel(icon: Icons.location_on_outlined, label: 'Where are you based?'),
        const SizedBox(height: 10),
        TextField(
          controller: _locationCtrl,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
          decoration: _fieldDec('Ndola, Copperbelt'),
        ),
        const SizedBox(height: 32),
        WizardContinueButton(
          onPressed: _next,
          label: 'Continue to portfolio',
          showArrow: true,
        ),
      ],
    );
  }

  // ── Step 1: Portfolio ────────────────────────────────────────────────────────

  Widget _buildPortfolioStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WizardSectionLabel(icon: Icons.camera_alt_outlined, label: 'Portfolio photos'),
        const SizedBox(height: 12),
        _DashedUploadArea(
          onTap: _pickCoverPhoto,
          child: _coverPhotoBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.memory(
                    _coverPhotoBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.upload_rounded, size: 32, color: AppColors.amber),
                    const SizedBox(height: 8),
                    Text(
                      'Upload cover photo',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.amber,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JPG or PNG, up to 10MB',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        // Gallery row
        Row(
          children: [
            ..._galleryBytes.take(3).map((bytes) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(bytes, fit: BoxFit.cover),
                  ),
                ),
              ),
            )),
            // Fill remaining slots up to 3 with placeholders
            ...List.generate(3 - _galleryBytes.take(3).length, (_) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.amber.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.camera_alt_outlined,
                        color: AppColors.amber, size: 24),
                  ),
                ),
              ),
            )),
            // Add button (hidden once 6 picked)
            if (_galleryBytes.length < 6)
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GestureDetector(
                    onTap: _addGalleryPhoto,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: AppColors.textHint, size: 28),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Add at least 4 photos — listings with 6+ photos get 3x more inquiries',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        WizardSectionLabel(icon: Icons.edit_outlined, label: 'Listing title'),
        const SizedBox(height: 10),
        TextField(
          controller: _titleCtrl,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
          decoration: _fieldDec('Mukuba Gardens — Open Air Venue'),
        ),
        const SizedBox(height: 20),
        WizardSectionLabel(icon: Icons.grid_view_outlined, label: 'Description'),
        const SizedBox(height: 10),
        TextField(
          controller: _descCtrl,
          maxLines: 4,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
          decoration: _fieldDec(
            'Spacious garden venue seating up to 300 guests...',
          ),
        ),
        const SizedBox(height: 32),
        WizardContinueButton(
          onPressed: _next,
          label: 'Continue to contact info',
          showArrow: true,
        ),
      ],
    );
  }

  // ── Step 2: Contact ──────────────────────────────────────────────────────────

  Widget _buildContactStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withAlpha(80)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.verified_user_outlined,
                  size: 20, color: AppColors.success),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Verified vendors ',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                      TextSpan(
                        text:
                            'get a trust badge and rank higher in match results. We may call to confirm these details.',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        WizardSectionLabel(icon: Icons.phone_outlined, label: 'Phone number'),
        const SizedBox(height: 10),
        _IconField(
          controller: _phoneCtrl,
          icon: Icons.phone_outlined,
          hint: '+260 97 712 3456',
          inputType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        WizardSectionLabel(
            icon: Icons.chat_bubble_outline_rounded, label: 'WhatsApp number'),
        const SizedBox(height: 10),
        _IconField(
          controller: _whatsappCtrl,
          icon: Icons.chat_bubble_outline_rounded,
          hint: '+260 97 712 3456',
          inputType: TextInputType.phone,
        ),
        const SizedBox(height: 20),
        WizardSectionLabel(icon: Icons.email_outlined, label: 'Email address'),
        const SizedBox(height: 10),
        _IconField(
          controller: _emailCtrl,
          icon: Icons.email_outlined,
          hint: 'bookings@mukubagardens.zm',
          inputType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        WizardSectionLabel(
            icon: Icons.location_on_outlined, label: 'Physical address'),
        const SizedBox(height: 10),
        _IconField(
          controller: _addressCtrl,
          icon: Icons.location_on_outlined,
          hint: 'Plot 14, Kansenshi Road, Ndola',
          inputType: TextInputType.streetAddress,
        ),
        const SizedBox(height: 20),
        WizardSectionLabel(
          icon: Icons.language_outlined,
          label: 'Social links',
          suffix: '(optional)',
        ),
        const SizedBox(height: 10),
        _IconField(
          controller: _instagramCtrl,
          icon: Icons.camera_alt_outlined,
          hint: 'Instagram handle',
          inputType: TextInputType.url,
        ),
        const SizedBox(height: 32),
        WizardContinueButton(
          onPressed: _next,
          label: 'Submit for verification',
          showArrow: true,
        ),
      ],
    );
  }

  // ── Step 3: Confirmation ─────────────────────────────────────────────────────

  Widget _buildConfirmationStep() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.success.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 40,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Submitted!',
                    style: AppTextStyles.displaySmall.copyWith(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your listing is now under review. Our team will verify your details and notify you within 24 hours.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  WedButton(
                    label: 'Go to dashboard',
                    onPressed: () {
                      ref.read(authProvider.notifier).completeVendorOnboarding();
                      context.go('/vendor/dashboard');
                    },
                    variant: WedButtonVariant.primaryDark,
                    height: 52,
                    borderRadius: 28,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _fieldDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.amber, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      );
}

// ── Icon-prefix field ─────────────────────────────────────────────────────────

class _IconField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final TextInputType inputType;

  const _IconField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.inputType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20, color: AppColors.textSecondary),
        hintText: hint,
        hintStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.amber, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      ),
    );
  }
}

// ── Dashed upload area ────────────────────────────────────────────────────────

class _DashedUploadArea extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _DashedUploadArea({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashBorderPainter(),
        child: Container(
          height: 116,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.amber.withAlpha(15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DashBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.amber
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    const radius = 12.0;

    final path = Path()
      ..addRRect(
          RRect.fromLTRBR(0, 0, size.width, size.height, const Radius.circular(radius)));

    final dashPath = _dashPath(path, dashWidth, dashSpace);
    canvas.drawPath(dashPath, paint);
  }

  Path _dashPath(Path source, double dashWidth, double dashSpace) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      double dist = 0;
      while (dist < metric.length) {
        final len = (dist + dashWidth).clamp(dist, metric.length);
        dest.addPath(metric.extractPath(dist, len), Offset.zero);
        dist += dashWidth + dashSpace;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
