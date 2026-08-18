import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_snack_bar.dart';
import '../../../widgets/wed_text_field.dart';
import '../../../widgets/wizard_widgets.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vendor_own_provider.dart';

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
  bool _isSubmitting = false;

  // Step 0 — Category & location
  String? _selectedCategory;
  final _locationCtrl = TextEditingController();
  final _customCategoryCtrl = TextEditingController();

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
    ('Venue', Icons.grid_view),
    ('Catering', Icons.restaurant_outlined),
    ('Photography', Icons.camera_alt_outlined),
    ('Decor & flowers', Icons.local_florist_outlined),
    ('DJ & MC', Icons.music_note_outlined),
    ('Transport', Icons.local_shipping_outlined),
    ('Wedding attire', Icons.checkroom_outlined),
    ('Cake & sweets', Icons.cake_outlined),
  ];

  // True when a vendor with an existing profile reopened this wizard from
  // their dashboard to update their listing, rather than a brand-new signup.
  // Drives prefill (so resubmitting doesn't null out existing fields — the
  // save endpoint is an upsert that writes every field it's sent) and the
  // confirmation copy.
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authProvider).vendorProfile;
    if (profile != null) {
      _isEditMode = true;
      _selectedCategory = profile.category;
      _locationCtrl.text = profile.location ?? '';
      _titleCtrl.text = profile.businessName;
      _descCtrl.text = profile.description ?? '';
      _phoneCtrl.text = profile.phone ?? '';
      _whatsappCtrl.text = profile.whatsapp ?? '';
      _emailCtrl.text = profile.contactEmail ?? '';
      _addressCtrl.text = profile.address ?? '';
      _instagramCtrl.text = profile.instagramHandle ?? '';
      return;
    }

    // Brand-new vendor, nothing saved yet — but the account itself already
    // holds the business name, email and phone typed one screen ago at
    // registration. Prefilling from it (still editable — this is a starting
    // point, not a lock) is the difference between "asked once" and "asked
    // twice for the same three things in ninety seconds."
    final user = ref.read(authProvider).user;
    if (user == null) return;
    _titleCtrl.text = user.name ?? '';
    _emailCtrl.text = user.email;
    _phoneCtrl.text = user.phone ?? '';
  }

  bool get _isCustomCategorySelected =>
      _selectedCategory != null &&
      !_categories.any(
        (c) => c.$1.toLowerCase() == _selectedCategory!.toLowerCase(),
      );

  void _addCustomCategory() {
    final raw = _customCategoryCtrl.text.trim();
    if (raw.isEmpty) return;
    final match = _categories.firstWhere(
      (c) => c.$1.toLowerCase() == raw.toLowerCase(),
      orElse: () => ('', Icons.category_outlined),
    );
    setState(() {
      _selectedCategory = match.$1.isNotEmpty ? match.$1 : raw;
      _customCategoryCtrl.clear();
    });
  }

  void _clearCustomCategory() => setState(() => _selectedCategory = null);

  @override
  void dispose() {
    _locationCtrl.dispose();
    _customCategoryCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _whatsappCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _instagramCtrl.dispose();
    super.dispose();
  }

  /// Required-field check for [step] — gates both "Continue" and the final
  /// "Submit for verification" so a vendor can no longer tap through three
  /// blank steps and only find out something was missing after the last one,
  /// which used to bounce them all the way back to step 0 or 1 with nothing
  /// on screen explaining why. Only fields without a "(optional)" suffix on
  /// their own label are required — Social links (step 2) is the one field
  /// in this wizard explicitly marked optional. Portfolio photos are
  /// deliberately exempt from step 1: a failed upload is already treated as
  /// non-blocking later in [_submit], so requiring one here would contradict
  /// that.
  String? _stepError(int step) {
    switch (step) {
      case 0:
        if (_selectedCategory == null || _selectedCategory!.isEmpty) {
          return 'Select a vendor category to continue.';
        }
        if (_locationCtrl.text.trim().isEmpty) {
          return "Add where you're based to continue.";
        }
        return null;
      case 1:
        if (_titleCtrl.text.trim().isEmpty) {
          return 'Add a listing title to continue.';
        }
        if (_descCtrl.text.trim().isEmpty) {
          return 'Add a short description to continue.';
        }
        return null;
      case 2:
        if (_phoneCtrl.text.trim().isEmpty) {
          return 'Add a phone number to continue.';
        }
        if (_whatsappCtrl.text.trim().isEmpty) {
          return 'Add a WhatsApp number to continue.';
        }
        if (_emailCtrl.text.trim().isEmpty) {
          return 'Add an email address to continue.';
        }
        if (_addressCtrl.text.trim().isEmpty) {
          return 'Add your physical address to continue.';
        }
        return null;
      default:
        return null;
    }
  }

  void _next() {
    final error = _stepError(_step);
    if (error != null) {
      showWedSnackBar(context, error, type: SnackType.error);
      return;
    }
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    }
  }

  Future<void> _submit() async {
    // _next() already gates steps 0 and 1 on the way here, so in practice
    // this only ever catches step 2 — swept as a loop rather than duplicating
    // the same jump-back logic three times, and left in place as cheap
    // insurance against a future change to how _step advances.
    for (final step in [0, 1, 2]) {
      final error = _stepError(step);
      if (error != null) {
        showWedSnackBar(context, error, type: SnackType.error);
        setState(() => _step = step);
        return;
      }
    }
    final businessName = _titleCtrl.text.trim();

    setState(() => _isSubmitting = true);
    final notifier = ref.read(vendorOwnProvider.notifier);
    final error = await notifier.createProfile(
      businessName: businessName,
      category: _selectedCategory!,
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      location: _locationCtrl.text.trim().isEmpty
          ? null
          : _locationCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      whatsapp: _whatsappCtrl.text.trim().isEmpty
          ? null
          : _whatsappCtrl.text.trim(),
      contactEmail: _emailCtrl.text.trim().isEmpty
          ? null
          : _emailCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      instagramHandle: _instagramCtrl.text.trim().isEmpty
          ? null
          : _instagramCtrl.text.trim(),
    );

    if (!mounted) return;
    if (error != null) {
      setState(() => _isSubmitting = false);
      showWedSnackBar(context, error, type: SnackType.error);
      return;
    }

    // Upload photos. A partial failure here shouldn't block the flow — the
    // vendor can add the rest from their dashboard afterwards.
    final photos = <(Uint8List, bool)>[
      if (_coverPhotoBytes != null) (_coverPhotoBytes!, true),
      for (final bytes in _galleryBytes) (bytes, false),
    ];
    var uploaded = 0;
    for (final (bytes, isFeatured) in photos) {
      final uploadError = await notifier.addMedia(
        bytes,
        'photo_$uploaded.jpg',
        isFeatured: isFeatured,
      );
      if (uploadError == null) uploaded++;
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (photos.isNotEmpty && uploaded < photos.length) {
      showWedSnackBar(
        context,
        '$uploaded of ${photos.length} photos uploaded — add the rest from your dashboard.',
        type: SnackType.info,
      );
    }
    _next();
  }

  Future<void> _pickCoverPhoto() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    setState(() => _coverPhotoBytes = bytes);
  }

  Future<void> _addGalleryPhoto() async {
    if (_galleryBytes.length >= 6) return;
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    setState(() => _galleryBytes.add(bytes));
  }

  void _removeCoverPhoto() => setState(() => _coverPhotoBytes = null);

  void _removeGalleryPhoto(int index) =>
      setState(() => _galleryBytes.removeAt(index));

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [_buildStep()],
                          ),
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
        WizardSectionLabel(
          icon: Icons.grid_view_outlined,
          label: 'Vendor category',
        ),
        const SizedBox(height: 12),
        // Keyed on the current selection so it re-seeds its displayed value
        // whenever _selectedCategory changes from outside this widget (e.g.
        // the "clear custom category" chip below) — a DropdownButtonFormField
        // only reads `initialValue` on its own first build, so without this
        // key an external clear would leave the dropdown still showing the
        // category that was just removed.
        DropdownButtonFormField<String>(
          key: ValueKey('category-$_selectedCategory-$_isCustomCategorySelected'),
          initialValue: _isCustomCategorySelected ? null : _selectedCategory,
          isExpanded: true,
          hint: const Text('Select a category'),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: _categories
              .map(
                (cat) => DropdownMenuItem(
                  value: cat.$1,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cat.$2, size: 18, color: AppColors.forestGreen),
                      const SizedBox(width: 10),
                      Text(cat.$1),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (value) => setState(() => _selectedCategory = value),
        ),
        const SizedBox(height: 12),
        if (_isCustomCategorySelected) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.forestGreen.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.forestGreen, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 14,
                  color: AppColors.forestGreen,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _selectedCategory!,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.forestGreen,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: _clearCustomCategory,
                    child: const Padding(
                      padding: EdgeInsets.all(3),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: AppColors.forestGreen,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: WedTextField(
                controller: _customCategoryCtrl,
                hint: 'Add another vendor type, e.g. Hair & Makeup',
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _addCustomCategory(),
                borderRadius: 10,
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: AppColors.forestGreen,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _addCustomCategory,
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "Don't see your category? Add your own — you can only pick one.",
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        WizardSectionLabel(
          icon: Icons.location_on_outlined,
          label: 'Where are you based?',
        ),
        const SizedBox(height: 10),
        WedTextField(
          controller: _locationCtrl,
          hint: 'Ndola, Copperbelt',
        ),
        const SizedBox(height: 32),
        WedButton(
          onPressed: _next,
          label: 'Continue to portfolio',
          trailingIcon: const Icon(Icons.arrow_forward),
        ),
      ],
    );
  }

  // ── Step 1: Portfolio ────────────────────────────────────────────────────────

  Widget _buildPortfolioStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WizardSectionLabel(
          icon: Icons.camera_alt_outlined,
          label: 'Portfolio photos',
        ),
        const SizedBox(height: 12),
        _DashedUploadArea(
          onTap: _pickCoverPhoto,
          child: _coverPhotoBytes != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.memory(
                        _coverPhotoBytes!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: _RemovePhotoButton(onTap: _removeCoverPhoto),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.upload,
                      size: 32,
                      color: AppColors.goldDeep,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Upload cover photo',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JPG or PNG, up to 10MB',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        // Gallery row
        Row(
          children: [
            ...List.generate(
              _galleryBytes.take(3).length,
              (i) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            _galleryBytes[i],
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: _RemovePhotoButton(
                            onTap: () => _removeGalleryPhoto(i),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Fill remaining slots up to 3 with placeholders
            ...List.generate(
              3 - _galleryBytes.take(3).length,
              (_) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.amber.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.camera_alt_outlined,
                        color: AppColors.goldDeep,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Add button (hidden once 6 picked)
            if (_galleryBytes.length < 6)
              Expanded(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Material(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _addGalleryPhoto,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: AppColors.textHint,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Add at least 4 photos — listings with 6+ photos get 3x more inquiries',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        WizardSectionLabel(icon: Icons.edit_outlined, label: 'Listing title'),
        const SizedBox(height: 10),
        WedTextField(
          controller: _titleCtrl,
          hint: 'Mukuba Gardens — Open Air Venue',
        ),
        const SizedBox(height: 20),
        WizardSectionLabel(
          icon: Icons.grid_view_outlined,
          label: 'Description',
        ),
        const SizedBox(height: 10),
        WedTextField(
          controller: _descCtrl,
          maxLines: 4,
          hint: 'Spacious garden venue seating up to 300 guests...',
        ),
        const SizedBox(height: 32),
        WedButton(
          onPressed: _next,
          label: 'Continue to contact info',
          trailingIcon: const Icon(Icons.arrow_forward),
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
              const Icon(
                Icons.verified_user_outlined,
                size: 20,
                color: AppColors.success,
              ),
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
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
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
          icon: Icons.chat_bubble_outlined,
          label: 'WhatsApp number',
        ),
        const SizedBox(height: 10),
        _IconField(
          controller: _whatsappCtrl,
          icon: Icons.chat_bubble_outlined,
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
          icon: Icons.location_on_outlined,
          label: 'Physical address',
        ),
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
        WedButton(
          onPressed: _submit,
          label: 'Submit for verification',
          trailingIcon: const Icon(Icons.arrow_forward),
          isLoading: _isSubmitting,
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
                      Icons.check,
                      size: 40,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isEditMode ? 'Updated!' : 'Submitted!',
                    style: AppTextStyles.displaySmall.copyWith(
                      color: AppColors.forestGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _isEditMode
                        ? 'Your listing has been updated with the new details.'
                        : 'Your listing is now under review. Our team will verify your details and notify you within 24 hours.',
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
                      ref
                          .read(authProvider.notifier)
                          .completeVendorOnboarding();
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
    return WedTextField(
      controller: controller,
      hint: hint,
      keyboardType: inputType,
      prefixIcon: icon,
      prefixIconColor: AppColors.textSecondary,
    );
  }
}

// ── Dashed upload area ────────────────────────────────────────────────────────

class _RemovePhotoButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;

  const _RemovePhotoButton({required this.onTap, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.forestGreen.withAlpha(200),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.close,
            size: size * 0.65,
            color: AppColors.textOnPrimary,
          ),
        ),
      ),
    );
  }
}

class _DashedUploadArea extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _DashedUploadArea({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
        RRect.fromLTRBR(
          0,
          0,
          size.width,
          size.height,
          const Radius.circular(radius),
        ),
      );

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
