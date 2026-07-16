import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/resource.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/share_helper.dart';
import '../../../models/invitation.dart';
import '../../../providers/invitation_provider.dart';
import '../../../widgets/highlighted_text.dart';
import '../../../widgets/typeahead_field.dart';
import '../../../widgets/wed_snack_bar.dart';

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
    _tabs = TabController(length: 2, vsync: this);
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
      backgroundColor: AppColors.cream,
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
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _OverviewTab(stats: stats, responses: state.responses),
          _GuestListTab(
            guests: state.guests,
            responses: state.responses,
            onAddGuest: () => _showGuestForm(context),
            onEditGuest: (g) => _showGuestForm(context, existing: g),
            onDeleteGuest: (id) => _confirmDeleteGuest(context, id),
            onSubmitRsvp: (g) => _showRsvpForm(context, g),
            onShareInvite: (g) => _shareGuestInvite(context, g),
            onResetRsvp: (rsvpId) => _resetGuestRsvp(context, rsvpId),
          ),
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
        onSave: (name, email, phone, relation) async {
          String? error;
          if (existing != null) {
            error = await ref.read(guestRsvpProvider.notifier).editGuest(
                  id: existing.id,
                  name: name,
                  email: email,
                  phone: phone,
                  relation: relation,
                );
          } else {
            error = await ref.read(guestRsvpProvider.notifier).addGuest(
                  name: name,
                  email: email,
                  phone: phone,
                  relation: relation,
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
            'This clears their current response and unlocks their personal invite link so they can respond again. Continue?'),
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
}

// ── Overview tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final RsvpStats stats;
  final List<RsvpResponse> responses;

  const _OverviewTab({required this.stats, required this.responses});

  @override
  Widget build(BuildContext context) {
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
            ],
          ),
        ),
        const SizedBox(height: 16),

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

        // Recent responses
        if (responses.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text('Recent Responses', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 10),
          ...responses.reversed.take(5).map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ResponseCard(response: r),
              )),
        ],
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
  final ValueChanged<String> onResetRsvp;

  const _GuestListTab({
    required this.guests,
    required this.responses,
    required this.onAddGuest,
    required this.onEditGuest,
    required this.onDeleteGuest,
    required this.onSubmitRsvp,
    required this.onShareInvite,
    required this.onResetRsvp,
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.forestGreen.withAlpha(12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text('👥', style: TextStyle(fontSize: 34)),
                ),
              ),
              const SizedBox(height: 20),
              Text('No guests yet', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              Text('Add guests to track their RSVPs.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: widget.onAddGuest,
                icon: const Icon(Icons.person_add_outlined, color: Colors.white),
                label: const Text('Add Guest'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ],
          ),
        ),
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
                      onResetRsvp:
                          rsvp != null ? () => widget.onResetRsvp(rsvp.id) : null,
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
  final VoidCallback? onResetRsvp;

  const _GuestCard({
    required this.guest,
    required this.rsvp,
    this.query = '',
    required this.onEdit,
    required this.onDelete,
    required this.onRsvp,
    required this.onShareInvite,
    required this.onResetRsvp,
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

  String get _statusIcon => switch (rsvp?.attending) {
        AttendingStatus.yes => '✅',
        AttendingStatus.no => '❌',
        AttendingStatus.maybe => '🤔',
        null => '⏳',
      };

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _statusColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Text(_statusIcon, style: const TextStyle(fontSize: 18)),
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
                  ),
                  if (guest.relation != null)
                    Text(guest.relation!,
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
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
                ],
              ),
            ),
            IconButton(
              onPressed: onDelete,
              tooltip: 'Remove guest',
              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(8),
              visualDensity: VisualDensity.compact,
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'rsvp') onRsvp();
                if (v == 'share') onShareInvite();
                if (v == 'reset') onResetRsvp?.call();
                if (v == 'edit') onEdit();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'rsvp',
                    child: ListTile(
                        leading: Icon(Icons.how_to_reg_outlined),
                        title: Text('Record RSVP'),
                        contentPadding: EdgeInsets.zero,
                        dense: true)),
                const PopupMenuItem(
                    value: 'share',
                    child: ListTile(
                        leading: Icon(Icons.ios_share_outlined),
                        title: Text('Share invite link'),
                        contentPadding: EdgeInsets.zero,
                        dense: true)),
                if (rsvp != null)
                  const PopupMenuItem(
                      value: 'reset',
                      child: ListTile(
                          leading: Icon(Icons.restart_alt),
                          title: Text('Reset RSVP'),
                          contentPadding: EdgeInsets.zero,
                          dense: true)),
                const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit guest'),
                        contentPadding: EdgeInsets.zero,
                        dense: true)),
              ],
              child: Icon(Icons.more_vert,
                  color: AppColors.textSecondary, size: 20),
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
  const _ResponseCard({required this.response});

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
    return _SoftCard(
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
  }
}

// ── Guest form sheet ──────────────────────────────────────────────────────────

class _GuestFormSheet extends StatefulWidget {
  final Guest? existing;
  final void Function(String name, String? email, String? phone, String? relation) onSave;

  const _GuestFormSheet({required this.existing, required this.onSave});

  @override
  State<_GuestFormSheet> createState() => _GuestFormSheetState();
}

class _GuestFormSheetState extends State<_GuestFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _relationCtrl;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _emailCtrl = TextEditingController(text: widget.existing?.email ?? '');
    _phoneCtrl = TextEditingController(text: widget.existing?.phone ?? '');
    _relationCtrl =
        TextEditingController(text: widget.existing?.relation ?? '');
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  widget.existing != null ? 'Save Changes' : 'Add Guest',
                  style: AppTextStyles.titleMedium
                      .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
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
      TextField(
        controller: ctrl,
        keyboardType: type,
        textCapitalization: TextCapitalization.words,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
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

  const _RsvpFormSheet({
    required this.guest,
    required this.existing,
    required this.onSave,
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
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Decrease guest count',
                      onPressed: () =>
                          setState(() => _count = (_count - 1).clamp(1, 20)),
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.secondary,
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _countError != null
                                ? AppColors.error
                                : AppColors.divider,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_count',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.headlineSmall,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Increase guest count',
                      onPressed: () =>
                          setState(() => _count = (_count + 1).clamp(1, 20)),
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.secondary,
                    ),
                  ],
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

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    widget.existing != null
                        ? 'Update RSVP'
                        : 'Record RSVP',
                    style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {int maxLines = 1}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: label,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}
