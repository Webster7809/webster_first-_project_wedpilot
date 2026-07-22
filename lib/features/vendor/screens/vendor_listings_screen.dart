import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/vendor_api_service.dart' show resolveMediaUrl;
import '../../../core/services/vendor_class_service.dart';
import '../../../core/state/resource.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/format_utils.dart';
import '../../../models/budget_class.dart';
import '../../../models/vendor_profile.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vendor_own_provider.dart';
import '../../../widgets/hamburger_menu_button.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_snack_bar.dart';
import '../../../widgets/wed_text_field.dart';

class VendorListingsScreen extends ConsumerStatefulWidget {
  const VendorListingsScreen({super.key});

  @override
  ConsumerState<VendorListingsScreen> createState() =>
      _VendorListingsScreenState();
}

class _VendorListingsScreenState extends ConsumerState<VendorListingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickAndAddImage() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (file == null) return;
    if (!mounted) return;
    final media = ref.read(vendorMediaProvider);
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    final error = await ref
        .read(vendorOwnProvider.notifier)
        .addMedia(bytes, file.name, isFeatured: media.isEmpty);
    if (error != null && mounted) {
      showWedSnackBar(context, error, type: SnackType.error);
    }
  }

  void _showAddServiceSheet({VendorService? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ServiceFormSheet(existing: existing),
    );
  }

  void _showAddPackageSheet({VendorPackage? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PackageFormSheet(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(vendorOwnProvider).status == ResourceStatus.initial) {
      Future.microtask(
        () => ref.read(vendorOwnProvider.notifier).loadOwnVendorData(),
      );
    }
    final services = ref.watch(vendorServicesProvider);
    final media = ref.watch(vendorMediaProvider);
    final packages = ref.watch(vendorPackagesProvider);
    final tabIndex = _tabController.index;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverOverlapAbsorber(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            sliver: SliverAppBar(
              backgroundColor: AppColors.forestGreen,
              automaticallyImplyLeading: false,
              leading: const HamburgerMenuButton(color: Colors.white),
              floating: true,
              snap: true,
              title: Text(
                'My Listings',
                style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarHeaderDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.amber,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withAlpha(153),
                labelStyle: AppTextStyles.labelLarge,
                tabs: [
                  Tab(text: 'Services (${services.length})'),
                  Tab(text: 'Packages (${packages.length})'),
                  Tab(text: 'Portfolio (${media.length})'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _ServicesTab(onAddService: _showAddServiceSheet),
            _PackagesTab(onAddPackage: _showAddPackageSheet),
            _PortfolioTab(
              onDeleteMedia: (id) async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Remove photo'),
                    content: const Text('Remove this photo from your portfolio?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          'Remove',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  final error = await ref
                      .read(vendorOwnProvider.notifier)
                      .deleteMedia(id);
                  if (!context.mounted) return;
                  if (error != null) {
                    showWedSnackBar(context, error, type: SnackType.error);
                  }
                }
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.amber,
        foregroundColor: Colors.white,
        onPressed: switch (tabIndex) {
          0 => () => _showAddServiceSheet(),
          1 => () => _showAddPackageSheet(),
          _ => _pickAndAddImage,
        },
        child: Icon(switch (tabIndex) {
          0 => Icons.add_rounded,
          1 => Icons.card_giftcard_rounded,
          _ => Icons.add_photo_alternate_outlined,
        }),
      ),
    );
  }
}

// ── Services tab ──────────────────────────────────────────────────────────────

class _ServicesTab extends ConsumerWidget {
  final void Function({VendorService? existing}) onAddService;

  const _ServicesTab({required this.onAddService});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(vendorServicesProvider);

    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        if (services.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    size: 64,
                    color: AppColors.forestGreen.withAlpha(80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No services yet',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to add your first service package.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList.separated(
              itemCount: services.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final service = services[index];
                return _ServiceCard(
                  service: service,
                  onEdit: () => onAddService(existing: service),
                  onToggleActive: () => ref
                      .read(vendorOwnProvider.notifier)
                      .toggleServiceActive(service.id),
                  onDelete: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete service'),
                        content: Text(
                            'Remove "${service.title}" from your listings?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: Text(
                              'Delete',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      final error = await ref
                          .read(vendorOwnProvider.notifier)
                          .deleteService(service.id);
                      if (!context.mounted) return;
                      if (error != null) {
                        showWedSnackBar(context, error, type: SnackType.error);
                      }
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

// ── Portfolio tab ─────────────────────────────────────────────────────────────

class _PortfolioTab extends ConsumerWidget {
  final void Function(String id) onDeleteMedia;

  const _PortfolioTab({required this.onDeleteMedia});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final media = ref.watch(vendorMediaProvider);

    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        if (media.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: AppColors.forestGreen.withAlpha(80),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No portfolio photos',
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.forestGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload photos of your work to attract couples.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6,
                childAspectRatio: 1,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = media[index];
                  return _PortfolioTile(
                    item: item,
                    onDelete: () => onDeleteMedia(item.id),
                    onToggleFeatured: () => ref
                        .read(vendorOwnProvider.notifier)
                        .toggleFeaturedMedia(item.id),
                  );
                },
                childCount: media.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Service card ──────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final VendorService service;
  final VoidCallback onEdit;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.service,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.forestGreen.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.forestGreen.withAlpha(15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.design_services_outlined,
                size: 22,
                color: AppColors.forestGreen,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'ZMW ${service.priceMin.toStringAsFixed(0)} – ${service.priceMax.toStringAsFixed(0)} / ${service.unit}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: service.isActive
                          ? AppColors.success.withAlpha(20)
                          : AppColors.textHint.withAlpha(40),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      service.isActive ? 'Active' : 'Draft',
                      style: AppTextStyles.caption.copyWith(
                        color: service.isActive
                            ? AppColors.success
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textSecondary,
              ),
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'toggle') onToggleActive();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(
                    service.isActive ? 'Set as draft' : 'Set as active',
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Delete',
                    style: TextStyle(color: AppColors.error),
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

// ── Portfolio tile ────────────────────────────────────────────────────────────

class _PortfolioTile extends StatelessWidget {
  final VendorMedia item;
  final VoidCallback onDelete;
  final VoidCallback onToggleFeatured;

  const _PortfolioTile({
    required this.item,
    required this.onDelete,
    required this.onToggleFeatured,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            resolveMediaUrl(item.url),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppColors.creamDark,
              child: const Icon(
                Icons.broken_image_outlined,
                color: AppColors.textHint,
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: item.isFeatured ? AppColors.amber : Colors.black.withAlpha(80),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onToggleFeatured,
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: Icon(
                    item.isFeatured
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            left: 4,
            child: Material(
              color: Colors.black.withAlpha(80),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onDelete,
                child: const SizedBox(
                  width: 26,
                  height: 26,
                  child: Icon(Icons.close, size: 16, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Service form sheet ────────────────────────────────────────────────────────

class _ServiceFormSheet extends ConsumerStatefulWidget {
  final VendorService? existing;

  const _ServiceFormSheet({this.existing});

  @override
  ConsumerState<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends ConsumerState<_ServiceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceMinCtrl;
  late final TextEditingController _priceMaxCtrl;
  late String _unit;
  String? _priceError;

  static const _units = ['event', 'hour', 'person', 'package', 'day'];

  @override
  void initState() {
    super.initState();
    final s = widget.existing;
    _titleCtrl = TextEditingController(text: s?.title ?? '');
    _descCtrl = TextEditingController(text: s?.description ?? '');
    _priceMinCtrl = TextEditingController(
      text: s != null ? s.priceMin.toStringAsFixed(0) : '',
    );
    _priceMaxCtrl = TextEditingController(
      text: s != null ? s.priceMax.toStringAsFixed(0) : '',
    );
    _unit = s?.unit ?? 'event';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceMinCtrl.dispose();
    _priceMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final min = double.tryParse(_priceMinCtrl.text.trim()) ?? 0;
    final max = double.tryParse(_priceMaxCtrl.text.trim()) ?? 0;

    if (min > max) {
      setState(() => _priceError = 'Min price must not exceed max price');
      return;
    }
    setState(() => _priceError = null);

    final vendorId = ref.read(vendorProfileProvider)?.id ?? '';
    final notifier = ref.read(vendorOwnProvider.notifier);

    final error = widget.existing != null
        ? await notifier.updateService(
            widget.existing!.copyWith(
              title: _titleCtrl.text.trim(),
              description: _descCtrl.text.trim().isEmpty
                  ? null
                  : _descCtrl.text.trim(),
              priceMin: min,
              priceMax: max,
              unit: _unit,
            ),
          )
        : await notifier.addService(
            VendorService(
              id: const Uuid().v4(),
              vendorId: vendorId,
              title: _titleCtrl.text.trim(),
              description: _descCtrl.text.trim().isEmpty
                  ? null
                  : _descCtrl.text.trim(),
              priceMin: min,
              priceMax: max,
              unit: _unit,
            ),
          );

    if (!mounted) return;
    if (error != null) {
      showWedSnackBar(context, error, type: SnackType.error);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 20),
              Text(
                isEdit ? 'Edit service' : 'New service',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.forestGreen,
                ),
              ),
              const SizedBox(height: 20),
              WedTextField(
                label: 'Service title',
                hint: 'e.g. Open Air Garden Package',
                controller: _titleCtrl,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 14),
              WedTextField(
                label: 'Description (optional)',
                hint: 'Describe what\'s included…',
                controller: _descCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: WedTextField(
                      label: 'Min price (ZMW)',
                      hint: '0',
                      controller: _priceMinCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v.trim()) == null) {
                          return 'Numbers only';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: WedTextField(
                      label: 'Max price (ZMW)',
                      hint: '0',
                      controller: _priceMaxCtrl,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v.trim()) == null) {
                          return 'Numbers only';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              if (_priceError != null) ...[
                const SizedBox(height: 4),
                Text(
                  _priceError!,
                  style: AppTextStyles.caption.copyWith(color: AppColors.error),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Priced per',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _units.map((unit) {
                    final selected = _unit == unit;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(unit),
                        selected: selected,
                        onSelected: (_) => setState(() => _unit = unit),
                        selectedColor: AppColors.forestGreen,
                        labelStyle: AppTextStyles.labelMedium.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                        side: BorderSide(
                          color: selected
                              ? AppColors.forestGreen
                              : AppColors.divider,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              WedButton(
                label: isEdit ? 'Save changes' : 'Add service',
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Packages tab ──────────────────────────────────────────────────────────────

class _PackagesTab extends ConsumerWidget {
  final void Function({VendorPackage? existing}) onAddPackage;

  const _PackagesTab({required this.onAddPackage});

  Future<void> _deletePackage(
      BuildContext context, WidgetRef ref, VendorPackage pkg) async {
    final notifier = ref.read(vendorOwnProvider.notifier);
    final remaining =
        ref.read(vendorPackagesProvider).where((p) => p.id != pkg.id).toList();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete package'),
        content: Text('Remove "${pkg.title}"? If this was your qualifying '
            'package, your wedding class may drop.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await notifier.savePackages(remaining);
    if (!context.mounted) return;
    if (error != null) {
      showWedSnackBar(context, error, type: SnackType.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(vendorOwnProfileProvider);
    final packages = ref.watch(vendorPackagesProvider);

    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (profile != null) ...[
                _ClassStatusCard(profile: profile),
                const SizedBox(height: 20),
              ],
              Text(
                'Your packages',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.forestGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Packages are what couples see bundled with your match. A '
                'starter package counts toward Flexible class; a luxury '
                'package with 3+ inclusions counts toward High Class.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              if (packages.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.card_giftcard_rounded,
                          size: 20, color: AppColors.forestGreen.withAlpha(120)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No packages yet — tap the button below to register '
                          'your first one.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final pkg in packages) ...[
                  _PackageCard(
                    package: pkg,
                    onEdit: () => onAddPackage(existing: pkg),
                    onDelete: () => _deletePackage(context, ref, pkg),
                  ),
                  const SizedBox(height: 10),
                ],
            ]),
          ),
        ),
      ],
    );
  }
}

/// Shows the wedding class this vendor has currently earned, plus the exact
/// criteria checklist toward the classes they haven't reached yet — so
/// "how do I become High Class?" is answered right on the screen.
class _ClassStatusCard extends StatelessWidget {
  final VendorProfile profile;

  const _ClassStatusCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final current = VendorClassService.classify(profile);
    final (badgeColor, badgeBg) = switch (current) {
      BudgetClass.highClass => (AppColors.amber, AppColors.adminAmberBg),
      BudgetClass.flexible => (AppColors.budgetGreen, AppColors.successBg),
      BudgetClass.budgetFriendly => (AppColors.neutralDark, AppColors.adminNeutralBg),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(current.icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your wedding class',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    Text(
                      current.displayName,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  current.subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (current == BudgetClass.highClass) ...[
            const SizedBox(height: 10),
            Text(
              'You\'ve earned the top class — couples choosing High Class '
              'weddings see you first. Keep your rating and packages up to stay here.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ] else ...[
            if (current == BudgetClass.budgetFriendly) ...[
              const SizedBox(height: 14),
              _CriteriaChecklist(
                title: 'To qualify as Flexible class',
                criteria: VendorClassService.flexibleCriteria(profile),
              ),
            ],
            const SizedBox(height: 14),
            _CriteriaChecklist(
              title: 'To qualify as High Class',
              criteria: VendorClassService.highClassCriteria(profile),
            ),
          ],
        ],
      ),
    );
  }
}

class _CriteriaChecklist extends StatelessWidget {
  final String title;
  final List<ClassCriterion> criteria;

  const _CriteriaChecklist({required this.title, required this.criteria});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (final c in criteria)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  c.met
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  size: 16,
                  color: c.met ? AppColors.budgetGreen : AppColors.textHint,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    c.label,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: c.met
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _PackageCard extends StatelessWidget {
  final VendorPackage package;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PackageCard({
    required this.package,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isLuxury = package.tier == VendorPackageTier.luxury;
    final tierColor = isLuxury ? AppColors.amber : AppColors.budgetGreen;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLuxury ? AppColors.amber.withAlpha(120) : AppColors.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tierColor.withAlpha(28),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isLuxury ? 'LUXURY' : 'STARTER',
                  style: AppTextStyles.caption.copyWith(
                    color: tierColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  package.title,
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 10),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded,
                    size: 18, color: AppColors.error),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in package.inclusions)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isLuxury ? Icons.diamond_outlined : Icons.check_rounded,
                    size: 13,
                    color: tierColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (package.price != null) ...[
            const SizedBox(height: 6),
            Text(
              fmtCurrency(package.price!),
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.forestGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Package form sheet ────────────────────────────────────────────────────────

class _PackageFormSheet extends ConsumerStatefulWidget {
  final VendorPackage? existing;

  const _PackageFormSheet({this.existing});

  @override
  ConsumerState<_PackageFormSheet> createState() => _PackageFormSheetState();
}

class _PackageFormSheetState extends ConsumerState<_PackageFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _inclusionsCtrl;
  late VendorPackageTier _tier;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _priceCtrl = TextEditingController(
      text: p?.price != null ? p!.price!.toStringAsFixed(0) : '',
    );
    _inclusionsCtrl =
        TextEditingController(text: p?.inclusions.join('\n') ?? '');
    _tier = p?.tier ?? VendorPackageTier.starter;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _inclusionsCtrl.dispose();
    super.dispose();
  }

  List<String> get _inclusions => _inclusionsCtrl.text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final notifier = ref.read(vendorOwnProvider.notifier);
    final existing = ref.read(vendorPackagesProvider);
    final price = _priceCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_priceCtrl.text.trim());

    final pkg = VendorPackage(
      id: widget.existing?.id ?? const Uuid().v4(),
      tier: _tier,
      title: _titleCtrl.text.trim(),
      inclusions: _inclusions,
      price: price,
    );
    final updated = widget.existing != null
        ? existing.map((p) => p.id == pkg.id ? pkg : p).toList()
        : [...existing, pkg];

    final error = await notifier.savePackages(updated);
    if (!mounted) return;
    if (error != null) {
      showWedSnackBar(context, error, type: SnackType.error);
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 20),
              Text(
                isEdit ? 'Edit package' : 'New package',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.forestGreen,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Package tier',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final tier in VendorPackageTier.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(tier == VendorPackageTier.luxury
                            ? '👑 Luxury'
                            : '🎁 Starter'),
                        selected: _tier == tier,
                        onSelected: (_) => setState(() => _tier = tier),
                        selectedColor: AppColors.forestGreen,
                        labelStyle: AppTextStyles.labelMedium.copyWith(
                          color: _tier == tier
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                        side: BorderSide(
                          color: _tier == tier
                              ? AppColors.forestGreen
                              : AppColors.divider,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _tier == VendorPackageTier.luxury
                    ? 'Counts toward High Class (needs 3+ inclusions).'
                    : 'Counts toward Flexible class.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              WedTextField(
                label: 'Package title',
                hint: 'e.g. Signature Luxury Experience',
                controller: _titleCtrl,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Title is required'
                    : null,
              ),
              const SizedBox(height: 14),
              WedTextField(
                label: 'What\'s included — one item per line',
                hint: 'Champagne welcome reception\nDedicated coordinator\nValet parking',
                controller: _inclusionsCtrl,
                maxLines: 6,
                validator: (v) {
                  final items = _inclusions;
                  if (items.isEmpty) return 'Add at least one inclusion';
                  if (items.length > 10) return 'At most 10 inclusions';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              WedTextField(
                label: 'Package price (ZMW, optional)',
                hint: 'Leave empty to price on request',
                controller: _priceCtrl,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = double.tryParse(v.trim());
                  if (n == null || n < 0) return 'Numbers only';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              WedButton(
                label: isEdit ? 'Save changes' : 'Register package',
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pinned tab bar header ────────────────────────────────────────────────────

class _TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarHeaderDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ColoredBox(color: AppColors.forestGreen, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarHeaderDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}
