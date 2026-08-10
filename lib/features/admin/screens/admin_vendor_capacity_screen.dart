import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/admin_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/vendor_profile.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/wed_avatar.dart';
import '../../../widgets/wed_snack_bar.dart';
import '../../../widgets/wed_text_field.dart';

/// Admin-only screen for filling in or correcting a vendor listing's stated
/// guest capacity — the counterpart to the vendor's own edit flow in
/// vendor_listings_screen.dart, for legacy listings created before the field
/// was mandatory (see backend/scripts/backfillGuestCapacity.js) or a
/// vendor-reported mistake, without waiting on the vendor to fix it themselves.
class AdminVendorCapacityScreen extends ConsumerStatefulWidget {
  const AdminVendorCapacityScreen({super.key});

  @override
  ConsumerState<AdminVendorCapacityScreen> createState() =>
      _AdminVendorCapacityScreenState();
}

class _AdminVendorCapacityScreenState
    extends ConsumerState<AdminVendorCapacityScreen> {
  final _searchCtrl = TextEditingController();
  final _expanded = <String>{};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Always returns a fresh list — the caller sorts it in place, and the
  /// unfiltered case would otherwise be sorting the very list instance
  /// [adminAllVendorsProvider] has cached.
  List<VendorProfile> _filter(List<VendorProfile> vendors) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return [...vendors];
    return vendors
        .where((v) =>
            v.businessName.toLowerCase().contains(q) ||
            v.category.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final vendors = ref.watch(adminAllVendorsProvider).valueOrNull ?? [];
    final filtered = _filter(vendors)
      ..sort((a, b) => a.businessName.compareTo(b.businessName));
    final missingCount = vendors
        .expand((v) => v.services)
        .where((s) => s.maxGuests == null)
        .length;

    return Scaffold(
      backgroundColor: AppColors.adminPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.divider,
        title: Text(
          'Guest Capacity',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          if (missingCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.adminAmberBg,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: AppColors.adminAmber.withAlpha(60)),
                  ),
                  child: Text(
                    '$missingCount missing',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.adminAmber,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: WedTextField(
              controller: _searchCtrl,
              hint: 'Search by business name or category…',
              prefixIcon: Icons.search,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const Divider(height: 1, color: AppColors.adminNeutralBg),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.storefront_outlined,
                            size: 56, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        Text('No vendors found',
                            style: AppTextStyles.headlineMedium),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final vendor = filtered[i];
                      return _VendorCapacityCard(
                        vendor: vendor,
                        expanded: _expanded.contains(vendor.id),
                        onToggle: () => setState(() {
                          if (!_expanded.remove(vendor.id)) {
                            _expanded.add(vendor.id);
                          }
                        }),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _VendorCapacityCard extends StatelessWidget {
  final VendorProfile vendor;
  final bool expanded;
  final VoidCallback onToggle;

  const _VendorCapacityCard({
    required this.vendor,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final missing = vendor.services.where((s) => s.maxGuests == null).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    WedAvatar(
                        imageUrl: vendor.logoUrl,
                        name: vendor.businessName,
                        radius: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(vendor.businessName,
                              style: AppTextStyles.titleMedium
                                  .copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(
                            '${vendor.category} · ${vendor.services.length} '
                            'listing${vendor.services.length == 1 ? '' : 's'}',
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    if (missing > 0)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.adminAmberBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.adminAmber.withAlpha(60)),
                        ),
                        child: Text(
                          missing == 1
                              ? '1 needs capacity'
                              : '$missing need capacity',
                          style: AppTextStyles.caption.copyWith(
                              color: AppColors.adminAmber,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: AppColors.adminNeutralBg),
            Padding(
              padding: const EdgeInsets.all(14),
              child: vendor.services.isEmpty
                  ? Text(
                      'This vendor has no service listings yet.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    )
                  : Column(
                      children: [
                        for (final service in vendor.services)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ServiceCapacityRow(
                                vendorId: vendor.id, service: service),
                          ),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ServiceCapacityRow extends ConsumerStatefulWidget {
  final String vendorId;
  final VendorService service;

  const _ServiceCapacityRow({required this.vendorId, required this.service});

  @override
  ConsumerState<_ServiceCapacityRow> createState() =>
      _ServiceCapacityRowState();
}

class _ServiceCapacityRowState extends ConsumerState<_ServiceCapacityRow> {
  late final TextEditingController _ctrl;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.service.maxGuests?.toString() ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final n = int.tryParse(_ctrl.text.trim());
    if (n == null || n <= 0) {
      setState(() => _error = 'Enter a whole number greater than 0');
      return;
    }
    if (n > AppConstants.maxRealisticGuestCount) {
      setState(() => _error =
          'Enter a realistic number (max ${AppConstants.maxRealisticGuestCount})');
      return;
    }
    // Read the token *before* entering the saving state: bailing out after
    // flipping _saving would strand this row on its spinner forever, since the
    // early return never reaches the finally below.
    final token = ref.read(authProvider.notifier).accessToken;
    if (token == null) {
      setState(() => _error = 'Your session has expired — sign in again.');
      return;
    }

    setState(() {
      _error = null;
      _saving = true;
    });

    try {
      await AdminApiService.instance
          .updateVendorServiceCapacity(token, widget.service.id, n);
      ref.invalidate(adminAllVendorsProvider);
      if (mounted) {
        showWedSnackBar(context, 'Guest capacity updated.', type: SnackType.success);
      }
    } on AdminApiException catch (e) {
      if (mounted) showWedSnackBar(context, e.message, type: SnackType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              widget.service.title,
              style: AppTextStyles.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: WedTextField(
            controller: _ctrl,
            hint: 'Max guests',
            errorText: _error,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            suffix: _saving
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.check_circle_outlined,
                        size: 20),
                    color: AppColors.adminGreen,
                    tooltip: 'Save',
                    onPressed: _save,
                  ),
          ),
        ),
      ],
    );
  }
}
