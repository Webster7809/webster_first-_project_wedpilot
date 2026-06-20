import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_snack_bar.dart';

class VendorVerificationScreen extends ConsumerWidget {
  const VendorVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendors = ref.watch(adminProvider).pendingVendors;

    return Scaffold(
      backgroundColor: AppColors.adminPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.divider,
        title: Text(
          'Vendor Approval',
          style: AppTextStyles.headlineSmall
              .copyWith(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: vendors.isEmpty
                      ? AppColors.adminGreenBg
                      : AppColors.adminAmberBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: vendors.isEmpty
                        ? AppColors.adminGreen.withAlpha(60)
                        : AppColors.adminAmber.withAlpha(60),
                  ),
                ),
                child: Text(
                  vendors.isEmpty ? 'All clear' : '${vendors.length} pending',
                  style: AppTextStyles.caption.copyWith(
                    color: vendors.isEmpty
                        ? AppColors.adminGreen
                        : AppColors.adminAmber,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: vendors.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 64,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 16),
                  Text('All caught up!',
                      style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    'No vendors pending review.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vendors.length,
              itemBuilder: (_, i) {
                final vendor = vendors[i];
                return _VerificationCard(
                  vendor: vendor,
                  onApprove: () {
                    ref
                        .read(adminProvider.notifier)
                        .approveVendor(vendor.id);
                    if (context.mounted) {
                      showWedSnackBar(
                        context,
                        '${vendor.name} approved!',
                        type: SnackType.success,
                      );
                    }
                  },
                  onReject: () {
                    ref
                        .read(adminProvider.notifier)
                        .rejectVendor(vendor.id);
                    if (context.mounted) {
                      showWedSnackBar(
                        context,
                        '${vendor.name} rejected.',
                        type: SnackType.error,
                      );
                    }
                  },
                );
              },
            ),
    );
  }
}

// ── Verification Card ─────────────────────────────────────────────────────────

class _VerificationCard extends StatefulWidget {
  final AdminVendor vendor;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _VerificationCard({
    required this.vendor,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_VerificationCard> createState() => _VerificationCardState();
}

class _VerificationCardState extends State<_VerificationCard> {
  bool _expanded = false;

  void _showApproveDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Approve vendor?'),
        content: Text(
            '${widget.vendor.name} will be listed on the platform for couples to discover.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onApprove();
            },
            child: const Text('Approve',
                style: TextStyle(color: AppColors.success)),
          ),
        ],
      ),
    );
  }

  void _showRejectSheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reason for rejection',
                style: AppTextStyles.headlineSmall),
            const SizedBox(height: 4),
            Text(
              'Optional — helps the vendor improve their submission.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'e.g. Missing business registration document…',
                hintStyle: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textHint),
                filled: true,
                fillColor: AppColors.adminPage,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            WedButton(
              label: 'Confirm Rejection',
              variant: WedButtonVariant.destructive,
              onPressed: () {
                Navigator.pop(ctx);
                widget.onReject();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header row ──────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.adminAmberBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront_outlined,
                      color: AppColors.adminAmber, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        v.name,
                        style: AppTextStyles.titleMedium
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${v.category} · Submitted ${v.submitted}',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.adminAmberBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.adminAmber.withAlpha(60)),
                  ),
                  child: Text(
                    'Pending',
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.adminAmber,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Docs row + expand toggle ─────────────────────────
            Row(
              children: [
                const Icon(Icons.description_outlined,
                    size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${v.docs} documents submitted',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      setState(() => _expanded = !_expanded),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expanded ? 'Hide details' : 'View details',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.adminIndigo,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.adminIndigo,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Expandable details ───────────────────────────────
            if (_expanded) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.adminPage,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DetailRow(
                        icon: Icons.email_outlined, text: v.email),
                    const SizedBox(height: 8),
                    _DetailRow(
                        icon: Icons.phone_outlined, text: v.phone),
                    const SizedBox(height: 8),
                    _DetailRow(
                        icon: Icons.location_on_outlined,
                        text: v.location),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),

            // ── Actions ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: WedButton(
                    label: 'Reject',
                    variant: WedButtonVariant.destructive,
                    onPressed: _showRejectSheet,
                    height: 40,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: WedButton(
                    label: 'Approve',
                    onPressed: _showApproveDialog,
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

// ── Detail Row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
