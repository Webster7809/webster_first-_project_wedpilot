import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/vendor_category_images.dart';
import '../../../core/state/resource.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/share_helper.dart';
import '../../../models/invitation.dart';
import '../../../models/vendor_profile.dart';
import '../../../providers/booking_provider.dart' show bookedVendorsProvider;
import '../../../providers/invitation_provider.dart';
import '../../../widgets/catering_estimate_card.dart';
import '../../../widgets/count_stepper.dart';
import '../../../widgets/highlighted_text.dart';
import '../../../widgets/typeahead_field.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_empty_state.dart';
import '../../../widgets/wed_snack_bar.dart';
import '../../../widgets/wed_text_field.dart';

/// Soft, flat shadowed container used throughout this screen instead of
/// Material's default [Card] elevation, matching the rest of the app's
/// (invitation gallery, dashboards) card treatment.
class _SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _SoftCard({required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class RsvpDashboardScreen extends ConsumerStatefulWidget {
  final String invitationId;
  const RsvpDashboardScreen({super.key, required this.invitationId});

  @override
  ConsumerState<RsvpDashboardScreen> createState() =>
      _RsvpDashboardScreenState();
}

class _RsvpDashboardScreenState extends ConsumerState<RsvpDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guestRsvpProvider);
    final stats = state.stats;
    if (ref.read(guestRsvpProvider.notifier).status == ResourceStatus.initial) {
      Future.microtask(() => ref.read(guestRsvpProvider.notifier).load());
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('RSVP Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Add guest',
            onPressed: () => _showGuestForm(context),
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.amber,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Guest List'),
            Tab(text: 'Check-in'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OverviewTab(
            stats: stats,
            responses: state.responses,
            guests: state.guests,
            onViewDetails: (g, r) => _showGuestDetails(context, g, r),
          ),
          _GuestListTab(
            guests: state.guests,
            responses: state.responses,
            onAddGuest: () => _showGuestForm(context),
            onEditGuest: (g) => _showGuestForm(context, existing: g),
            onDeleteGuest: (id) => _confirmDeleteGuest(context, id),
            onSubmitRsvp: (g) => _showRsvpForm(context, g),
            onShareInvite: (g) => _shareGuestInvite(context, g),
            onViewDetails: (g) => _showGuestDetails(
              context,
              g,
              state.responses.where((r) => r.guestId == g.id).firstOrNull,
            ),
          ),
          _CheckInTab(guests: state.guests),
        ],
      ),
    );
  }

  // ── Guest form ────────────────────────────────────────────────────────────

  void _showGuestForm(BuildContext context, {Guest? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GuestFormSheet(
        existing: existing,
        onSave: (name, email, phone, relation, maxPartySize) async {
          String? error;
          if (existing != null) {
            error = await ref.read(guestRsvpProvider.notifier).editGuest(
                  id: existing.id,
                  name: name,
                  email: email,
                  phone: phone,
                  relation: relation,
                  maxPartySize: maxPartySize,
                );
          } else {
            error = await ref.read(guestRsvpProvider.notifier).addGuest(
                  name: name,
                  email: email,
                  phone: phone,
                  relation: relation,
                  invitationId:
                      widget.invitationId.isEmpty ? null : widget.invitationId,
                  maxPartySize: maxPartySize,
                );
          }
          if (!context.mounted) return;
          if (error != null) {
            showWedSnackBar(context, error, type: SnackType.error);
          } else {
            showWedSnackBar(
              context,
              existing != null ? 'Guest updated.' : 'Guest added.',
              type: SnackType.success,
            );
          }
        },
      ),
    );
  }

  void _confirmDeleteGuest(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Guest'),
        content: const Text(
            'This will also remove their RSVP response. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final error = await ref.read(guestRsvpProvider.notifier).deleteGuest(id);
              if (!context.mounted) return;
              if (error != null) {
                showWedSnackBar(context, error, type: SnackType.error);
              } else {
                showWedSnackBar(context, 'Guest removed.', type: SnackType.info);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showRsvpForm(BuildContext context, Guest guest) {
    final existing = ref
        .read(guestRsvpProvider)
        .responses
        .where((r) => r.guestId == guest.id)
        .firstOrNull;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RsvpFormSheet(
        guest: guest,
        existing: existing,
        onReset:
            existing != null ? () => _resetGuestRsvp(context, existing.id) : null,
        onSave: (status, count, meal, notes, message) async {
          final error =
              await ref.read(guestRsvpProvider.notifier).submitRsvp(
                    guestId: guest.id,
                    attending: status,
                    guestCount: count,
                    mealPreference: meal,
                    dietaryNotes: notes,
                    message: message,
                    invitationId: widget.invitationId.isEmpty ? null : widget.invitationId,
                  );
          if (!context.mounted) return;
          if (error != null) {
            showWedSnackBar(context, error, type: SnackType.error);
          } else {
            showWedSnackBar(context, 'RSVP recorded.', type: SnackType.success);
          }
        },
      ),
    );
  }

  Future<void> _shareGuestInvite(BuildContext context, Guest guest) async {
    // If this guest's link already exists locally, share it synchronously
    // (preserves the web share-sheet's user-gesture context); otherwise a
    // network round trip to generate it is unavoidable first.
    if (guest.inviteUrl != null) {
      await shareWithFallback(
        context,
        text: 'You\'re invited to celebrate our wedding! 💍\n\n'
            'View your personal invitation here: ${guest.inviteUrl}',
        subject: 'Your Wedding Invitation',
      );
      return;
    }

    final updated = await ref.read(guestRsvpProvider.notifier).getGuestInviteLink(
          guestId: guest.id,
          invitationId: widget.invitationId,
        );
    if (!context.mounted) return;
    if (updated?.inviteUrl == null) {
      showWedSnackBar(context, 'Could not create this guest\'s invite link.', type: SnackType.error);
      return;
    }
    await shareWithFallback(
      context,
      text: 'You\'re invited to celebrate our wedding! 💍\n\n'
          'View your personal invitation here: ${updated!.inviteUrl}',
      subject: 'Your Wedding Invitation',
    );
  }

  void _resetGuestRsvp(BuildContext context, String rsvpId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset RSVP'),
        content: const Text(
            'This clears their current response — their invitation will show as not yet responded, and they can submit a fresh answer through their personal link. Continue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(guestRsvpProvider.notifier).deleteRsvp(rsvpId);
              if (context.mounted) {
                showWedSnackBar(context, 'RSVP reset.', type: SnackType.info);
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showGuestDetails(BuildContext context, Guest guest, RsvpResponse? rsvp) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GuestDetailsSheet(
        guest: guest,
        rsvp: rsvp,
        onToggleCheckin: () => ref.read(guestRsvpProvider.notifier).toggleCheckin(guest.id),
        onShareInvite: () => _shareGuestInvite(context, guest),
        onLoadHistory: rsvp != null
            ? () => ref.read(guestRsvpProvider.notifier).fetchRsvpHistory(rsvp.id)
            : null,
      ),
    );
  }
}

// ── Overview tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  final RsvpStats stats;
  final List<RsvpResponse> responses;
  final List<Guest> guests;
  final void Function(Guest guest, RsvpResponse? rsvp) onViewDetails;

  const _OverviewTab({
    required this.stats,
    required this.responses,
    required this.guests,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkedIn = guests.where((g) => g.checkedIn).length;
    final effectiveGuestCount = ref.watch(effectiveGuestCountProvider);
    final bookedVendorsAsync = ref.watch(bookedVendorsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stat cards — 2x2 grid instead of a cramped single row
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    value: '${stats.attending}',
                    label: 'Attending',
                    color: AppColors.success)),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    value: '${stats.declined}',
                    label: 'Declined',
                    color: AppColors.error)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    value: '${stats.maybe}',
                    label: 'Maybe',
                    color: AppColors.warning)),
            const SizedBox(width: 12),
            Expanded(
                child: _StatCard(
                    value: '${stats.pending}',
                    label: 'Pending',
                    color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 20),

        // Guest count + rates
        _SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Attendance Summary', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 12),
              _InfoRow(
                  label: 'Total guests attending',
                  value: '${stats.totalAttending} people'),
              _InfoRow(
                  label: 'Total invited',
                  value: '${stats.totalInvited} guests'),
              _InfoRow(
                  label: 'Response rate',
                  value: '${stats.responseRate.toStringAsFixed(0)}%'),
              _InfoRow(
                  label: 'Acceptance rate',
                  value: '${stats.acceptanceRate.toStringAsFixed(0)}%'),
              _InfoRow(
                  label: 'Checked in',
                  value: '$checkedIn / ${stats.totalInvited}'),
            ],
          ),
        ),

        // Vendor capacity vs. confirmed guests — reuses the same
        // VendorProfile.canServeGuestCount/fittingGuestCapacity helpers the
        // AI vendor matcher and discovery filter already use, just checked
        // here against the couple's *booked* vendors instead of the
        // candidate pool.
        if (effectiveGuestCount != null && effectiveGuestCount > 0) ...[
          const SizedBox(height: 16),
          bookedVendorsAsync.when(
            data: (vendors) => vendors.isEmpty
                ? const SizedBox.shrink()
                : _SoftCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Vendor Capacity', style: AppTextStyles.headlineSmall),
                        const SizedBox(height: 4),
                        Text(
                          'Checked against your $effectiveGuestCount confirmed guests.',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        for (final vendor in vendors)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _VendorCapacityRow(
                              vendor: vendor,
                              guestCount: effectiveGuestCount,
                            ),
                          ),
                      ],
                    ),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
        const SizedBox(height: 16),

        const CateringEstimateCard(),

        // Response progress bar
        _SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('Response Rate',
                        style: AppTextStyles.headlineSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${stats.responded}/${stats.totalInvited}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: stats.totalInvited > 0
                    ? stats.responded / stats.totalInvited
                    : 0,
                backgroundColor: AppColors.progressTrack,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.secondary),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),

        // Meal preferences
        if (stats.mealCounts.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Meal Preferences', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 10),
          _SoftCard(
            child: Column(
              children: stats.mealCounts.entries
                  .map((e) => _MealRow(
                        meal: e.key,
                        count: e.value,
                        total: stats.totalAttending,
                      ))
                  .toList(),
            ),
          ),
        ],

        // Custom question tallies (choice-type questions only — see
        // RsvpStats.questionTallies)
        if (stats.questionTallies.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Question Responses', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 10),
          for (final entry in stats.questionTallies.entries) ...[
            _SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 10),
                  for (final option in entry.value.entries)
                    _MealRow(
                      meal: option.key,
                      count: option.value,
                      total: stats.totalAttending,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],

        // Recent responses
        if (responses.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Recent Responses', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 10),
          ...responses.reversed.take(5).map((r) {
            final guest = guests.where((g) => g.id == r.guestId).firstOrNull;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ResponseCard(
                response: r,
                onTap: guest != null ? () => onViewDetails(guest, r) : null,
              ),
            );
          }),
        ],
      ],
    );
  }
}

/// One booked vendor's stated capacity vs. the couple's confirmed guest
/// count — reuses [VendorProfile.canServeGuestCount]/[fittingGuestCapacity]
/// rather than any new capacity logic (see [_OverviewTab]).
class _VendorCapacityRow extends StatelessWidget {
  final VendorProfile vendor;
  final int guestCount;

  const _VendorCapacityRow({required this.vendor, required this.guestCount});

  @override
  Widget build(BuildContext context) {
    final fitting = vendor.fittingGuestCapacity(guestCount);
    final IconData icon;
    final Color color;
    final String message;
    if (vendor.maxGuestCapacity == null) {
      icon = Icons.help_outline;
      color = AppColors.textSecondary;
      message = 'Capacity not stated';
    } else if (vendor.canServeGuestCount(guestCount)) {
      icon = Icons.check_circle_outline;
      color = AppColors.success;
      message = fitting != null
          ? 'Can accommodate — fits up to $fitting guests'
          : 'Can accommodate your guest count';
    } else {
      icon = Icons.warning_amber_outlined;
      color = AppColors.error;
      message =
          'Capacity insufficient — largest package fits ${vendor.maxGuestCapacity} guests';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${vendor.businessName} · ${vendor.category}',
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w600),
              ),
              Text(message, style: AppTextStyles.bodySmall.copyWith(color: color)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Guest list tab ────────────────────────────────────────────────────────────

class _GuestListTab extends StatefulWidget {
  final List<Guest> guests;
  final List<RsvpResponse> responses;
  final VoidCallback onAddGuest;
  final ValueChanged<Guest> onEditGuest;
  final ValueChanged<String> onDeleteGuest;
  final ValueChanged<Guest> onSubmitRsvp;
  final ValueChanged<Guest> onShareInvite;
  final ValueChanged<Guest> onViewDetails;

  const _GuestListTab({
    required this.guests,
    required this.responses,
    required this.onAddGuest,
    required this.onEditGuest,
    required this.onDeleteGuest,
    required this.onSubmitRsvp,
    required this.onShareInvite,
    required this.onViewDetails,
  });

  @override
  State<_GuestListTab> createState() => _GuestListTabState();
}

class _GuestListTabState extends State<_GuestListTab> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<Guest> _filterGuests(List<Guest> guests, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return guests;
    return guests
        .where((g) =>
            g.name.toLowerCase().contains(q) ||
            (g.email ?? '').toLowerCase().contains(q) ||
            (g.phone ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final guests = widget.guests;
    final responses = widget.responses;
    if (guests.isEmpty) {
      return WedEmptyState(
        icon: Icons.people_outlined,
        title: 'No guests yet',
        message: 'Add guests to track their RSVPs.',
        ctaLabel: 'Add Guest',
        onCtaTap: widget.onAddGuest,
        imageUrl: VendorCategoryImages.galleryFor('DJ & MC')[0],
      );
    }

    final responseMap = {for (final r in responses) r.guestId: r};
    final filtered = _filterGuests(guests, _query);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: TypeaheadField<Guest>(
            controller: _searchCtrl,
            focusNode: _searchFocus,
            hint: 'Search guests...',
            prefixIcon: Icons.search,
            onChanged: (v) => setState(() => _query = v),
            suggestionsCallback: (q) => _filterGuests(guests, q).take(8).toList(),
            displayStringForOption: (g) => g.name,
            onSelected: (g) => setState(() => _query = g.name),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No guests match "$_query".',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final g = filtered[i];
                    final rsvp = responseMap[g.id];
                    return _GuestCard(
                      guest: g,
                      rsvp: rsvp,
                      query: _query,
                      onEdit: () => widget.onEditGuest(g),
                      onDelete: () => widget.onDeleteGuest(g.id),
                      onRsvp: () => widget.onSubmitRsvp(g),
                      onShareInvite: () => widget.onShareInvite(g),
                      onViewDetails: () => widget.onViewDetails(g),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _GuestCard extends StatelessWidget {
  final Guest guest;
  final RsvpResponse? rsvp;
  final String query;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRsvp;
  final VoidCallback onShareInvite;
  final VoidCallback onViewDetails;

  const _GuestCard({
    required this.guest,
    required this.rsvp,
    this.query = '',
    required this.onEdit,
    required this.onDelete,
    required this.onRsvp,
    required this.onShareInvite,
    required this.onViewDetails,
  });

  Color get _statusColor => switch (rsvp?.attending) {
        AttendingStatus.yes => AppColors.success,
        AttendingStatus.no => AppColors.error,
        AttendingStatus.maybe => AppColors.warning,
        null => AppColors.textSecondary,
      };

  String get _statusLabel => switch (rsvp?.attending) {
        AttendingStatus.yes => 'Attending',
        AttendingStatus.no => 'Declined',
        AttendingStatus.maybe => 'Maybe',
        null => 'Pending',
      };

  @override
  Widget build(BuildContext context) {
    final initial = guest.name.isNotEmpty ? guest.name[0].toUpperCase() : '?';
    // One quiet caption line under the name: relation, one contact detail,
    // and the party size when they've confirmed with extra guests.
    final subtitleParts = <String>[
      if (guest.relation?.isNotEmpty ?? false) guest.relation!,
      if (guest.email?.isNotEmpty ?? false)
        guest.email!
      else if (guest.phone?.isNotEmpty ?? false)
        guest.phone!,
      if (rsvp != null &&
          rsvp!.attending == AttendingStatus.yes &&
          rsvp!.guestCount > 1)
        '${rsvp!.guestCount} guests',
    ];

    return _SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Guest info — tap opens the full details sheet; the action row
          // below has its own explicit buttons, so this is deliberately not
          // one giant tap target covering the whole card.
          InkWell(
            onTap: onViewDetails,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _statusColor.withAlpha(22),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initial,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: _statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HighlightedText(
                        text: guest.name,
                        query: query,
                        style: AppTextStyles.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitleParts.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitleParts.join(' · '),
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (guest.cardNumber != null) ...[
                        const SizedBox(height: 4),
                        _CardNumberChip(guest: guest),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor.withAlpha(26),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _statusLabel,
                        style: AppTextStyles.caption.copyWith(
                          color: _statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (guest.checkedIn) ...[
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified,
                              size: 13, color: AppColors.success),
                          const SizedBox(width: 3),
                          Text(
                            'Checked in',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ],
            ),
            ),
          ),

          // ── Always-visible actions — no hidden menus ──────────
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: _GuestAction(
                    icon: Icons.how_to_reg_outlined,
                    label: rsvp == null ? 'RSVP' : 'Update',
                    onTap: onRsvp,
                  ),
                ),
                Expanded(
                  child: _GuestAction(
                    icon: Icons.ios_share_outlined,
                    label: 'Share',
                    onTap: onShareInvite,
                  ),
                ),
                Expanded(
                  child: _GuestAction(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    onTap: onEdit,
                  ),
                ),
                Expanded(
                  child: _GuestAction(
                    icon: Icons.delete_outlined,
                    label: 'Remove',
                    color: AppColors.error,
                    onTap: onDelete,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One labeled action in a guest card's bottom action row — icon + text so
/// every action (especially Remove) is visible at a glance, never buried in
/// an overflow menu.
class _GuestAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _GuestAction({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: c),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption.copyWith(
          color: c,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// A guest's door check-in code, tappable to copy — the couple needs to get
/// this onto a physical card somehow, and typing a 6-digit number by hand
/// from the screen is exactly the kind of thing copy/paste should replace.
class _CardNumberChip extends StatelessWidget {
  final Guest guest;
  const _CardNumberChip({required this.guest});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.iconTint,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          await Clipboard.setData(ClipboardData(text: guest.cardNumber!));
          if (context.mounted) {
            showWedSnackBar(context, 'Card number copied.', type: SnackType.success);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.badge_outlined, size: 12, color: AppColors.forestGreen),
              const SizedBox(width: 4),
              Text(
                'Card #${guest.cardNumber}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.forestGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Check-in tab ──────────────────────────────────────────────────────────────

class _CheckInTab extends ConsumerStatefulWidget {
  final List<Guest> guests;
  const _CheckInTab({required this.guests});

  @override
  ConsumerState<_CheckInTab> createState() => _CheckInTabState();
}

class _CheckInTabState extends ConsumerState<_CheckInTab> {
  final _codeCtrl = TextEditingController();
  final _focusNode = FocusNode();
  bool _submitting = false;
  Guest? _lastSuccess;
  String? _lastError;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty || _submitting) return;
    setState(() { _submitting = true; _lastSuccess = null; _lastError = null; });

    final (guest, error) = await ref.read(guestRsvpProvider.notifier).checkInGuest(code);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _lastSuccess = guest;
      _lastError = error;
    });
    // Cleared either way — a couple standing at the door scanning a queue of
    // guests needs the field ready for the next card immediately, not left
    // holding whatever number just failed.
    _codeCtrl.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final invited = widget.guests.where((g) => g.isInvited).length;
    final checkedIn = widget.guests.where((g) => g.checkedIn).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Verify a guest', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Enter the number printed on the guest\'s card to confirm '
                'they\'re on your list.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              WedTextField(
                label: 'Card number',
                controller: _codeCtrl,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              WedButton(
                label: 'Check in',
                isLoading: _submitting,
                onPressed: _submitting ? null : _submit,
              ),
            ],
          ),
        ),
        if (_lastSuccess != null) ...[
          const SizedBox(height: 16),
          _CheckInResultCard(
            success: true,
            title: _lastSuccess!.name,
            message: 'Verified — this card matches your guest list.',
          ),
        ],
        if (_lastError != null) ...[
          const SizedBox(height: 16),
          _CheckInResultCard(
            success: false,
            title: 'Not verified',
            message: _lastError!,
          ),
        ],
        const SizedBox(height: 20),
        _SoftCard(
          child: Row(
            children: [
              const Icon(Icons.how_to_reg_outlined, color: AppColors.forestGreen),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$checkedIn of $invited guests checked in',
                  style: AppTextStyles.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CheckInResultCard extends StatelessWidget {
  final bool success;
  final String title;
  final String message;
  const _CheckInResultCard({
    required this.success,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final color = success ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(success ? Icons.check_circle : Icons.error_outline, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleMedium.copyWith(color: color)),
                const SizedBox(height: 2),
                Text(message, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared stat widgets ───────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCard(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.headlineMedium
                  .copyWith(color: color, fontSize: 24)),
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Text(value,
              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  final String meal;
  final int count;
  final int total;
  const _MealRow(
      {required this.meal, required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(meal,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              Text('$count guest${count == 1 ? '' : 's'}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.divider,
            valueColor:
                AlwaysStoppedAnimation<Color>(AppColors.secondary),
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}

class _ResponseCard extends StatelessWidget {
  final RsvpResponse response;
  final VoidCallback? onTap;
  const _ResponseCard({required this.response, this.onTap});

  Color get _color => switch (response.attending) {
        AttendingStatus.yes => AppColors.success,
        AttendingStatus.no => AppColors.error,
        AttendingStatus.maybe => AppColors.warning,
      };

  String get _icon => switch (response.attending) {
        AttendingStatus.yes => '✅',
        AttendingStatus.no => '❌',
        AttendingStatus.maybe => '🤔',
      };

  @override
  Widget build(BuildContext context) {
    final card = _SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(response.guestName, style: AppTextStyles.titleMedium),
                if (response.guestCount > 0)
                  Text('${response.guestCount} guest${response.guestCount == 1 ? '' : 's'}',
                      style: AppTextStyles.caption),
                if (response.mealPreference != null)
                  Text('Meal: ${response.mealPreference}',
                      style: AppTextStyles.caption),
                if (response.message != null)
                  Text('"${response.message}"',
                      style: AppTextStyles.caption
                          .copyWith(fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _color.withAlpha(31),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              response.attending.name[0].toUpperCase() +
                  response.attending.name.substring(1),
              style: AppTextStyles.caption
                  .copyWith(color: _color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

// ── Guest details sheet ───────────────────────────────────────────────────────

/// Everything known about one guest in a single read-only place: contact
/// info, their door check-in card, and — if they've responded — the full
/// RSVP (meal preference, dietary notes, personal message) that the Overview
/// tab's "Recent Responses" and the guest list's card only show pieces of.
class _GuestDetailsSheet extends StatelessWidget {
  final Guest guest;
  final RsvpResponse? rsvp;
  final VoidCallback onToggleCheckin;
  final VoidCallback onShareInvite;

  /// Null when there's no RSVP yet to have a history. Present only for
  /// couple-initiated edits — see [RsvpHistoryEntry].
  final Future<List<RsvpHistoryEntry>> Function()? onLoadHistory;

  const _GuestDetailsSheet({
    required this.guest,
    required this.rsvp,
    required this.onToggleCheckin,
    required this.onShareInvite,
    this.onLoadHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
          const SizedBox(height: 16),
          Text(guest.name, style: AppTextStyles.headlineMedium),
          if (guest.relation?.isNotEmpty ?? false) ...[
            const SizedBox(height: 2),
            Text(guest.relation!,
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 16),

          // ── Contact ──────────────────────────────────────────
          if (guest.email?.isNotEmpty ?? false)
            _InfoRow(label: 'Email', value: guest.email!),
          if (guest.phone?.isNotEmpty ?? false)
            _InfoRow(label: 'Phone', value: guest.phone!),

          // ── Door check-in ────────────────────────────────────
          const SizedBox(height: 8),
          _SoftCard(
            child: Row(
              children: [
                Icon(
                  guest.checkedIn ? Icons.verified : Icons.badge_outlined,
                  color: guest.checkedIn ? AppColors.success : AppColors.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        guest.cardNumber != null ? 'Card #${guest.cardNumber}' : 'No card number yet',
                        style: AppTextStyles.titleMedium,
                      ),
                      Text(
                        guest.checkedIn
                            ? 'Checked in${guest.checkedInAt != null ? ' at ${guest.checkedInAt!.toLocal().hour.toString().padLeft(2, '0')}:${guest.checkedInAt!.toLocal().minute.toString().padLeft(2, '0')}' : ''}'
                            : 'Not checked in yet',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onToggleCheckin,
                  child: Text(guest.checkedIn ? 'Undo' : 'Check in'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text('RSVP', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 10),
          if (rsvp == null)
            Text(
              'No response yet.',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            )
          else ...[
            _InfoRow(
              label: 'Attending',
              value: rsvp!.attending.name[0].toUpperCase() + rsvp!.attending.name.substring(1),
            ),
            if (rsvp!.guestCount > 0)
              _InfoRow(label: 'Party size', value: '${rsvp!.guestCount}'),
            if (rsvp!.mealPreference?.isNotEmpty ?? false)
              _InfoRow(label: 'Meal preference', value: rsvp!.mealPreference!),
            if (rsvp!.dietaryNotes?.isNotEmpty ?? false)
              _InfoRow(label: 'Dietary notes', value: rsvp!.dietaryNotes!),
            for (final answer in rsvp!.answers)
              _InfoRow(
                label: answer.questionText ?? 'Question',
                value: answer.answerJson.isNotEmpty
                    ? answer.answerJson.join(', ')
                    : (answer.answerText ?? '—'),
              ),
            if (rsvp!.message?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text('"${rsvp!.message}"',
                  style: AppTextStyles.bodyMedium.copyWith(fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 4),
            _InfoRow(
              label: 'Responded',
              value: '${rsvp!.respondedAt.toLocal()}'.split('.').first,
            ),
            if (onLoadHistory != null) ...[
              const SizedBox(height: 12),
              _HistorySection(onLoad: onLoadHistory!),
            ],
          ],

          const SizedBox(height: 20),
          WedButton(
            label: 'Share invite link',
            variant: WedButtonVariant.secondary,
            height: 46,
            icon: const Icon(Icons.ios_share_outlined, size: 18),
            onPressed: () {
              Navigator.pop(context);
              onShareInvite();
            },
          ),
        ],
      ),
    );
  }
}

// ── Collapsed-by-default RSVP change history (couple-initiated edits only) ──

class _HistorySection extends StatefulWidget {
  final Future<List<RsvpHistoryEntry>> Function() onLoad;
  const _HistorySection({required this.onLoad});

  @override
  State<_HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<_HistorySection> {
  bool _expanded = false;
  bool _loading = false;
  List<RsvpHistoryEntry>? _entries;

  Future<void> _toggle() async {
    if (_expanded) {
      setState(() => _expanded = false);
      return;
    }
    setState(() { _expanded = true; _loading = _entries == null; });
    if (_entries == null) {
      final entries = await widget.onLoad();
      if (mounted) setState(() { _entries = entries; _loading = false; });
    }
  }

  String _label(AttendingStatus? status) {
    if (status == null) return 'no response';
    return status.name[0].toUpperCase() + status.name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _toggle,
          child: Row(
            children: [
              Icon(_expanded ? Icons.expand_less : Icons.history,
                  size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text('Change history',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if ((_entries ?? const []).isEmpty)
            Text('No manual edits recorded.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textHint))
          else
            for (final entry in _entries!)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '${'${entry.changedAt.toLocal()}'.split('.').first} — '
                  '${_label(entry.previousStatus)} → ${_label(entry.newStatus)} '
                  '(${entry.previousGuestCount ?? '—'} → ${entry.newGuestCount} guests)',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
              ),
        ],
      ],
    );
  }
}

// ── Guest form sheet ──────────────────────────────────────────────────────────

class _GuestFormSheet extends StatefulWidget {
  final Guest? existing;
  final void Function(
    String name,
    String? email,
    String? phone,
    String? relation,
    int? maxPartySize,
  ) onSave;

  const _GuestFormSheet({required this.existing, required this.onSave});

  @override
  State<_GuestFormSheet> createState() => _GuestFormSheetState();
}

class _GuestFormSheetState extends State<_GuestFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _relationCtrl;
  late int _maxPartySize;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _emailCtrl = TextEditingController(text: widget.existing?.email ?? '');
    _phoneCtrl = TextEditingController(text: widget.existing?.phone ?? '');
    _relationCtrl =
        TextEditingController(text: widget.existing?.relation ?? '');
    _maxPartySize = widget.existing?.maxPartySize ?? 1;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _relationCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Guest name is required.');
      return;
    }
    setState(() => _nameError = null);
    Navigator.pop(context);
    widget.onSave(
      name,
      _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      _relationCtrl.text.trim().isEmpty ? null : _relationCtrl.text.trim(),
      _maxPartySize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
            const SizedBox(height: 16),
            Text(
              widget.existing != null ? 'Edit Guest' : 'Add Guest',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: 20),
            _field(_nameCtrl, 'Full name *', error: _nameError,
                onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            }),
            const SizedBox(height: 12),
            _field(_relationCtrl, 'Relation (e.g. Family, Friend)'),
            const SizedBox(height: 12),
            _field(_emailCtrl, 'Email (optional)',
                type: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field(_phoneCtrl, 'Phone (optional)',
                type: TextInputType.phone),
            const SizedBox(height: 16),
            Text('Max people on this invitation', style: AppTextStyles.labelLarge),
            const SizedBox(height: 4),
            Text(
              'A family/group invitation — e.g. "the Banda family, max 4" — '
              'rejects an RSVP for more than this many people.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            CountStepper(
              value: _maxPartySize,
              onChanged: (v) => setState(() => _maxPartySize = v),
            ),
            const SizedBox(height: 24),
            WedButton(
              label: widget.existing != null ? 'Save Changes' : 'Add Guest',
              variant: WedButtonVariant.accent,
              height: 50,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? error,
    TextInputType type = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) =>
      WedTextField(
        controller: ctrl,
        label: label,
        errorText: error,
        keyboardType: type,
        textCapitalization: TextCapitalization.words,
        onChanged: onChanged,
      );
}

// ── RSVP form sheet ───────────────────────────────────────────────────────────

class _RsvpFormSheet extends StatefulWidget {
  final Guest guest;
  final RsvpResponse? existing;
  final void Function(
    AttendingStatus status,
    int guestCount,
    String? meal,
    String? dietary,
    String? message,
  ) onSave;

  /// Clears the existing response (with its own confirmation) — only
  /// offered when there is a response to clear.
  final VoidCallback? onReset;

  const _RsvpFormSheet({
    required this.guest,
    required this.existing,
    required this.onSave,
    this.onReset,
  });

  @override
  State<_RsvpFormSheet> createState() => _RsvpFormSheetState();
}

class _RsvpFormSheetState extends State<_RsvpFormSheet> {
  late AttendingStatus _status;
  late int _count;
  late final TextEditingController _mealCtrl;
  late final TextEditingController _dietaryCtrl;
  late final TextEditingController _messageCtrl;
  String? _countError;

  @override
  void initState() {
    super.initState();
    _status = widget.existing?.attending ?? AttendingStatus.yes;
    _count = widget.existing?.guestCount ?? 1;
    _mealCtrl =
        TextEditingController(text: widget.existing?.mealPreference ?? '');
    _dietaryCtrl =
        TextEditingController(text: widget.existing?.dietaryNotes ?? '');
    _messageCtrl =
        TextEditingController(text: widget.existing?.message ?? '');
  }

  @override
  void dispose() {
    _mealCtrl.dispose();
    _dietaryCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_status == AttendingStatus.yes && _count < 1) {
      setState(() => _countError = 'Must be at least 1.');
      return;
    }
    setState(() => _countError = null);
    Navigator.pop(context);
    widget.onSave(
      _status,
      _status == AttendingStatus.no ? 0 : _count,
      _mealCtrl.text.trim().isEmpty ? null : _mealCtrl.text.trim(),
      _dietaryCtrl.text.trim().isEmpty ? null : _dietaryCtrl.text.trim(),
      _messageCtrl.text.trim().isEmpty ? null : _messageCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
              const SizedBox(height: 16),
              Text('RSVP for ${widget.guest.name}',
                  style: AppTextStyles.headlineMedium),
              const SizedBox(height: 20),

              // Attending status
              Text('Will they attend? *', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              Row(
                children: AttendingStatus.values.map((s) {
                  final label = switch (s) {
                    AttendingStatus.yes => 'Yes ✅',
                    AttendingStatus.no => 'No ❌',
                    AttendingStatus.maybe => 'Maybe 🤔',
                  };
                  final color = switch (s) {
                    AttendingStatus.yes => AppColors.success,
                    AttendingStatus.no => AppColors.error,
                    AttendingStatus.maybe => AppColors.warning,
                  };
                  final selected = _status == s;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Material(
                        color: selected ? color.withAlpha(31) : AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: selected ? color : AppColors.divider,
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => setState(() => _status = s),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(label,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.caption.copyWith(
                                  color: selected
                                      ? color
                                      : AppColors.textSecondary,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.normal,
                                )),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Guest count (only if attending)
              if (_status != AttendingStatus.no) ...[
                Text('Number of guests *', style: AppTextStyles.labelLarge),
                const SizedBox(height: 8),
                CountStepper(
                  value: _count,
                  max: widget.guest.maxPartySize ?? 20,
                  hasError: _countError != null,
                  onChanged: (v) => setState(() => _count = v),
                ),
                if (_countError != null)
                  Text(_countError!,
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.error)),
                const SizedBox(height: 16),
                _field(_mealCtrl, 'Meal preference (e.g. Chicken, Veg)'),
                const SizedBox(height: 12),
                _field(_dietaryCtrl, 'Dietary notes (optional)'),
                const SizedBox(height: 12),
              ],

              _field(_messageCtrl, 'Message (optional)', maxLines: 2),
              const SizedBox(height: 24),

              WedButton(
                label: widget.existing != null ? 'Update RSVP' : 'Record RSVP',
                variant: WedButtonVariant.accent,
                height: 50,
                onPressed: _save,
              ),
              if (widget.existing != null && widget.onReset != null) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onReset!();
                    },
                    icon: const Icon(Icons.restart_alt,
                        size: 16, color: AppColors.error),
                    label: Text(
                      'Reset this RSVP',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {int maxLines = 1}) =>
      WedTextField(
        controller: ctrl,
        label: label,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
      );
}
