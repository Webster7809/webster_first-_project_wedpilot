import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/vendor_api_service.dart' show resolveMediaUrl;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/format_utils.dart';
import '../../../models/vendor_profile.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/wed_avatar.dart';

/// Read-only, back-office view of everything on file for one vendor —
/// contact details, tier/verification state, CRS performance stats, every
/// priced service listing, every package, and their media count. Reuses the
/// same [adminAllVendorsProvider] fetch the Guest Capacity screen already
/// pulls (every vendor, every category, already includes services/packages),
/// so opening a vendor here costs no extra request. Distinct from the
/// couple-facing VendorProfileScreen, which is a marketing view that hides
/// exactly the fields admins need (email, tier, per-listing pricing/active
/// state, verification status).
class AdminVendorDetailScreen extends ConsumerWidget {
  final String vendorId;
  const AdminVendorDetailScreen({super.key, required this.vendorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsAsync = ref.watch(adminAllVendorsProvider);
    final vendors = vendorsAsync.valueOrNull;

    if (vendors == null && vendorsAsync.isLoading) {
      return Scaffold(
        backgroundColor: AppColors.adminPage,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    VendorProfile? vendor;
    for (final v in vendors ?? const <VendorProfile>[]) {
      if (v.id == vendorId) {
        vendor = v;
        break;
      }
    }

    if (vendor == null) {
      return Scaffold(
        backgroundColor: AppColors.adminPage,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColors.textPrimary),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.storefront_outlined,
                  size: 56, color: AppColors.textHint),
              const SizedBox(height: 12),
              Text('Vendor not found', style: AppTextStyles.headlineMedium),
            ],
          ),
        ),
      );
    }

    return _AdminVendorDetailBody(vendor: vendor);
  }
}

class _AdminVendorDetailBody extends StatelessWidget {
  final VendorProfile vendor;
  const _AdminVendorDetailBody({required this.vendor});

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
    final (tierBg, tierFg, tierLabel) = switch (vendor.tier) {
      VendorTier.premium => (AppColors.adminIndigoBg, AppColors.adminIndigo, 'Premium'),
      VendorTier.pro => (AppColors.adminBlueBg, AppColors.adminBlue, 'Pro'),
      VendorTier.free => (AppColors.adminNeutralBg, AppColors.adminNeutral, 'Free'),
    };

    return Scaffold(
      backgroundColor: AppColors.adminPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        shadowColor: AppColors.divider,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          vendor.businessName,
          style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Header card ──────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
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
                Row(
                  children: [
                    WedAvatar(
                        imageUrl: vendor.logoUrl,
                        name: vendor.businessName,
                        radius: 26),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(vendor.businessName,
                              style: AppTextStyles.titleLarge
                                  .copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(
                            '${vendor.category}'
                            '${vendor.location != null ? ' · ${vendor.location}' : ''}',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Badge(bg: statusBg, fg: statusFg, label: statusLabel),
                    _Badge(bg: tierBg, fg: tierFg, label: tierLabel),
                    if (vendor.isFeatured)
                      const _Badge(
                          bg: AppColors.adminAmberBg,
                          fg: AppColors.adminAmber,
                          label: 'Featured'),
                    if (vendor.isCustomEntry)
                      const _Badge(
                          bg: AppColors.adminNeutralBg,
                          fg: AppColors.adminNeutral,
                          label: 'Admin-added listing'),
                  ],
                ),
                if (vendor.description != null && vendor.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(vendor.description!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textPrimary, height: 1.5)),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Contact ──────────────────────────────────────────────────
          _Section(
            title: 'Contact',
            child: Column(
              children: [
                _ContactRow(icon: Icons.phone_outlined, label: vendor.phone, launchScheme: 'tel:'),
                _ContactRow(icon: Icons.email_outlined, label: vendor.contactEmail, launchScheme: 'mailto:'),
                _ContactRow(icon: Icons.language_outlined, label: vendor.website, launchScheme: 'https://'),
                _ContactRow(icon: Icons.chat_outlined, label: vendor.whatsapp, launchScheme: 'https://wa.me/'),
                _ContactRow(icon: Icons.camera_alt_outlined, label: vendor.instagramHandle),
                _ContactRow(icon: Icons.location_on_outlined, label: vendor.address ?? vendor.location),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Performance / CRS stats ─────────────────────────────────
          _Section(
            title: 'Performance',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatChip(
                    icon: Icons.star_outlined,
                    label: vendor.rating != null
                        ? '${vendor.rating!.toStringAsFixed(1)} rating (${vendor.feedbackCount})'
                        : 'No ratings yet'),
                _StatChip(
                    icon: Icons.celebration_outlined,
                    label: '${vendor.weddingsCompleted} weddings completed'),
                if (vendor.respondsInMinutes != null)
                  _StatChip(
                      icon: Icons.bolt_outlined,
                      label: 'Responds in ~${vendor.respondsInMinutes!.round()} min'),
                if (vendor.onTimeRate != null)
                  _StatChip(
                      icon: Icons.schedule_outlined,
                      label: '${(vendor.onTimeRate! * 100).round()}% on-time'),
                if (vendor.recommendRate != null)
                  _StatChip(
                      icon: Icons.thumb_up_alt_outlined,
                      label: '${(vendor.recommendRate! * 100).round()}% recommend'),
                _StatChip(
                    icon: Icons.insights_outlined,
                    label: 'Composite score ${vendor.compositeScore.toStringAsFixed(0)}'),
              ],
            ),
          ),

          if (vendor.styleTags.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Section(
              title: 'Style tags',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: vendor.styleTags
                    .map((t) => _Badge(
                        bg: AppColors.adminPinkBg,
                        fg: AppColors.adminPink,
                        label: t))
                    .toList(),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── Services ─────────────────────────────────────────────────
          _Section(
            title: 'Services (${vendor.services.length})',
            child: vendor.services.isEmpty
                ? Text('No service listings yet.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary))
                : Column(
                    children: [
                      for (final s in vendor.services) _ServiceTile(service: s),
                    ],
                  ),
          ),

          const SizedBox(height: 16),

          // ── Packages ─────────────────────────────────────────────────
          _Section(
            title: 'Packages (${vendor.packages.length})',
            child: vendor.packages.isEmpty
                ? Text('No wedding-class packages registered.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary))
                : Column(
                    children: [
                      for (final p in vendor.packages) _PackageTile(package: p),
                    ],
                  ),
          ),

          const SizedBox(height: 16),

          // ── Media ────────────────────────────────────────────────────
          _Section(
            title: 'Media (${vendor.media.length})',
            child: vendor.media.isEmpty
                ? Text('No photos or videos uploaded yet.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary))
                : SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: vendor.media.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final m = vendor.media[i];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Stack(
                            children: [
                              CachedNetworkImage(
                                imageUrl: resolveMediaUrl(m.thumbnailUrl ?? m.url),
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                memCacheWidth: 144,
                                errorWidget: (context, url, error) => Container(
                                  width: 72,
                                  height: 72,
                                  color: AppColors.adminNeutralBg,
                                  child: const Icon(Icons.broken_image_outlined,
                                      color: AppColors.textHint, size: 20),
                                ),
                              ),
                              if (m.isVideo)
                                const Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Icon(Icons.play_circle_fill,
                                      color: Colors.white, size: 18),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),

          if (vendor.blockedDates.isNotEmpty) ...[
            const SizedBox(height: 16),
            _Section(
              title: 'Blocked dates (${vendor.blockedDates.length})',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: vendor.blockedDates
                    .map((d) => _Badge(
                        bg: AppColors.adminNeutralBg,
                        fg: AppColors.adminNeutral,
                        label: d))
                    .toList(),
              ),
            ),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Section wrapper ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          Text(title,
              style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Contact row ────────────────────────────────────────────────────────────────

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String? label;
  final String? launchScheme;

  const _ContactRow({required this.icon, this.label, this.launchScheme});

  @override
  Widget build(BuildContext context) {
    final hasValue = label != null && label!.trim().isNotEmpty;
    final canLaunch = hasValue && launchScheme != null;

    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: hasValue ? AppColors.textSecondary : AppColors.textHint),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasValue ? label! : 'Not provided',
              style: AppTextStyles.bodySmall.copyWith(
                color: hasValue
                    ? (canLaunch ? AppColors.adminIndigo : AppColors.textPrimary)
                    : AppColors.textHint,
                decoration: canLaunch ? TextDecoration.underline : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    if (!canLaunch) return row;
    return InkWell(
      onTap: () => launchUrl(_buildContactUri(launchScheme!, label!)),
      child: row,
    );
  }

  /// [value] may already be a full URL (website/whatsapp pasted with
  /// `https://`) or a bare phone/number/handle — normalized against
  /// [scheme] either way so `tel:`/`mailto:` never end up with a stray
  /// `https://` prefix and `https://` links never end up doubled.
  static Uri _buildContactUri(String scheme, String value) {
    if (scheme == 'tel:' || scheme == 'mailto:') {
      return Uri.parse('$scheme$value');
    }
    if (value.startsWith('http')) return Uri.parse(value);
    return Uri.parse('$scheme$value');
  }
}

// ── Small badges/chips ────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final Color bg;
  final Color fg;
  final String label;
  const _Badge({required this.bg, required this.fg, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withAlpha(60)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.adminPage,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.forestGreen),
          const SizedBox(width: 6),
          Text(label,
              style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Service / package tiles ───────────────────────────────────────────────────

class _ServiceTile extends StatelessWidget {
  final VendorService service;
  const _ServiceTile({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.adminPage,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(service.title,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              ),
              _Badge(
                bg: service.isActive ? AppColors.adminGreenBg : AppColors.adminNeutralBg,
                fg: service.isActive ? AppColors.adminGreen : AppColors.adminNeutral,
                label: service.isActive ? 'Active' : 'Inactive',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${fmtCurrency(service.priceMin.round())} – ${fmtAmount(service.priceMax.round())} / ${service.unit}',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            service.maxGuests != null
                ? 'Serves up to ${service.maxGuests} guests'
                : 'Guest capacity not set',
            style: AppTextStyles.caption.copyWith(
              color: service.maxGuests != null ? AppColors.textSecondary : AppColors.adminAmber,
            ),
          ),
          if (service.description != null && service.description!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(service.description!,
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  final VendorPackage package;
  const _PackageTile({required this.package});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.adminPage,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(package.title,
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              ),
              _Badge(
                bg: package.tier == VendorPackageTier.luxury
                    ? AppColors.adminIndigoBg
                    : AppColors.adminBlueBg,
                fg: package.tier == VendorPackageTier.luxury
                    ? AppColors.adminIndigo
                    : AppColors.adminBlue,
                label: package.tier == VendorPackageTier.luxury ? 'Luxury' : 'Starter',
              ),
            ],
          ),
          if (package.price != null) ...[
            const SizedBox(height: 6),
            Text(fmtCurrency(package.price!.round()),
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ],
          if (package.inclusions.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...package.inclusions.map((inc) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check, size: 13, color: AppColors.adminGreen),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(inc,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.textSecondary)),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
