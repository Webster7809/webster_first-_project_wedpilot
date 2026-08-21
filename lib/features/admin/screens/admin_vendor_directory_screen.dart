import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/vendor_profile.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/wed_avatar.dart';
import '../../../widgets/wed_text_field.dart';

/// Every registered vendor — verified or still pending — searchable, each row
/// opening [AdminVendorDetailScreen]. Unlike [VendorVerificationScreen]
/// (pending-only, tuned for the approve/reject workflow), this is the browse
/// path for "show me everything about vendor X" regardless of their
/// verification state.
class AdminVendorDirectoryScreen extends ConsumerStatefulWidget {
  const AdminVendorDirectoryScreen({super.key});

  @override
  ConsumerState<AdminVendorDirectoryScreen> createState() =>
      _AdminVendorDirectoryScreenState();
}

class _AdminVendorDirectoryScreenState
    extends ConsumerState<AdminVendorDirectoryScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<VendorProfile> _filter(List<VendorProfile> vendors) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return [...vendors];
    return vendors
        .where((v) =>
            v.businessName.toLowerCase().contains(q) ||
            v.category.toLowerCase().contains(q) ||
            (v.location ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final vendorsAsync = ref.watch(adminAllVendorsProvider);
    final vendors = vendorsAsync.valueOrNull ?? [];
    final filtered = _filter(vendors)
      ..sort((a, b) => a.businessName.compareTo(b.businessName));

    return Scaffold(
      backgroundColor: AppColors.adminPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.divider,
        title: Text(
          'All Vendors',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.adminIndigoBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.adminIndigo.withAlpha(60)),
                ),
                child: Text(
                  '${vendors.length} total',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.adminIndigo,
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
              hint: 'Search by business name, category, or location…',
              prefixIcon: Icons.search,
              onChanged: (_) => setState(() {}),
            ),
          ),
          const Divider(height: 1, color: AppColors.adminNeutralBg),
          Expanded(
            child: vendorsAsync.isLoading && vendors.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
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
                          return _VendorRow(
                            vendor: vendor,
                            onTap: () => context.push(
                              AppRoutes.adminVendorDetail
                                  .replaceFirst(':id', vendor.id),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _VendorRow extends StatelessWidget {
  final VendorProfile vendor;
  final VoidCallback onTap;

  const _VendorRow({required this.vendor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (statusBg, statusFg, statusLabel) = switch (vendor.verificationStatus) {
      VerificationStatus.verified => (
          AppColors.adminGreenBg,
          AppColors.adminGreen,
          'Verified'
        ),
      VerificationStatus.pending => (
          AppColors.adminAmberBg,
          AppColors.adminAmber,
          'Pending'
        ),
      VerificationStatus.rejected => (
          AppColors.adminRedBg,
          AppColors.error,
          'Rejected'
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
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
                        '${vendor.category}'
                        '${vendor.location != null ? ' · ${vendor.location}' : ''}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusFg.withAlpha(60)),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTextStyles.caption.copyWith(
                        color: statusFg, fontWeight: FontWeight.w600),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
