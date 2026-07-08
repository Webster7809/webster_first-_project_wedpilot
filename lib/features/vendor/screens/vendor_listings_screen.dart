import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/vendor_api_service.dart' show resolveMediaUrl;
import '../../../core/state/resource.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/vendor_profile.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/vendor_own_provider.dart';
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
    _tabController = TabController(length: 2, vsync: this);
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

  @override
  Widget build(BuildContext context) {
    if (ref.watch(vendorOwnProvider).status == ResourceStatus.initial) {
      Future.microtask(
        () => ref.read(vendorOwnProvider.notifier).loadOwnVendorData(),
      );
    }
    final services = ref.watch(vendorServicesProvider);
    final media = ref.watch(vendorMediaProvider);
    final isServicesTab = _tabController.index == 0;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        automaticallyImplyLeading: false,
        title: Text(
          'My Listings',
          style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.amber,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withAlpha(153),
          labelStyle: AppTextStyles.labelLarge,
          tabs: [
            Tab(text: 'Services (${services.length})'),
            Tab(text: 'Portfolio (${media.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ServicesTab(onAddService: _showAddServiceSheet),
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.amber,
        foregroundColor: Colors.white,
        onPressed: isServicesTab
            ? () => _showAddServiceSheet()
            : _pickAndAddImage,
        child: Icon(
          isServicesTab
              ? Icons.add_rounded
              : Icons.add_photo_alternate_outlined,
        ),
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

    if (services.isEmpty) {
      return Center(
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
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
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
                content: Text('Remove "${service.title}" from your listings?'),
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

    if (media.isEmpty) {
      return Center(
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
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) {
        final item = media[index];
        return _PortfolioTile(
          item: item,
          onDelete: () => onDeleteMedia(item.id),
          onToggleFeatured: () =>
              ref.read(vendorOwnProvider.notifier).toggleFeaturedMedia(item.id),
        );
      },
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
            child: GestureDetector(
              onTap: onToggleFeatured,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: item.isFeatured
                      ? AppColors.amber
                      : Colors.black.withAlpha(80),
                  shape: BoxShape.circle,
                ),
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
          Positioned(
            top: 4,
            left: 4,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(80),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
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
