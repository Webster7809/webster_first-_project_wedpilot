import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/invitation.dart';
import '../../../providers/invitation_provider.dart';
import '../../../widgets/wed_snack_bar.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('RSVP Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Add guest',
            onPressed: () => _showGuestForm(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
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
        onSave: (name, email, phone, relation) {
          String? error;
          if (existing != null) {
            error = ref.read(guestRsvpProvider.notifier).editGuest(
                  id: existing.id,
                  name: name,
                  email: email,
                  phone: phone,
                  relation: relation,
                );
          } else {
            error = ref.read(guestRsvpProvider.notifier).addGuest(
                  name: name,
                  email: email,
                  phone: phone,
                  relation: relation,
                );
          }
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
            onPressed: () {
              Navigator.pop(context);
              ref.read(guestRsvpProvider.notifier).deleteGuest(id);
              showWedSnackBar(context, 'Guest removed.', type: SnackType.info);
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
        onSave: (status, count, meal, notes, message) {
          final error =
              ref.read(guestRsvpProvider.notifier).submitRsvp(
                    guestId: guest.id,
                    guestName: guest.name,
                    attending: status,
                    guestCount: count,
                    mealPreference: meal,
                    dietaryNotes: notes,
                    message: message,
                  );
          if (error != null) {
            showWedSnackBar(context, error, type: SnackType.error);
          } else {
            showWedSnackBar(context, 'RSVP recorded.', type: SnackType.success);
          }
        },
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
        // Stat cards
        Row(
          children: [
            Expanded(
                child: _StatCard(
                    value: '${stats.attending}',
                    label: 'Attending',
                    color: AppColors.success)),
            const SizedBox(width: 8),
            Expanded(
                child: _StatCard(
                    value: '${stats.declined}',
                    label: 'Declined',
                    color: AppColors.error)),
            const SizedBox(width: 8),
            Expanded(
                child: _StatCard(
                    value: '${stats.maybe}',
                    label: 'Maybe',
                    color: AppColors.warning)),
            const SizedBox(width: 8),
            Expanded(
                child: _StatCard(
                    value: '${stats.pending}',
                    label: 'Pending',
                    color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 16),

        // Guest count + rates
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                    value:
                        '${stats.responseRate.toStringAsFixed(0)}%'),
                _InfoRow(
                    label: 'Acceptance rate',
                    value:
                        '${stats.acceptanceRate.toStringAsFixed(0)}%'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Response progress bar
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Response Rate', style: AppTextStyles.headlineSmall),
                    Text(
                      '${stats.responded}/${stats.totalInvited}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: stats.totalInvited > 0
                      ? stats.responded / stats.totalInvited
                      : 0,
                  backgroundColor: Theme.of(context).colorScheme.outlineVariant.withAlpha(102),
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.secondary),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Meal preferences
        if (stats.mealCounts.isNotEmpty) ...[
          Text('Meal Preferences', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 10),
          ...stats.mealCounts.entries.map((e) => _MealRow(
                meal: e.key,
                count: e.value,
                total: stats.totalAttending,
              )),
          const SizedBox(height: 16),
        ],

        // Recent responses
        if (responses.isNotEmpty) ...[
          Text('Recent Responses', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 10),
          ...responses
              .reversed
              .take(5)
              .map((r) => _ResponseCard(response: r)),
        ],
      ],
    );
  }
}

// ── Guest list tab ────────────────────────────────────────────────────────────

class _GuestListTab extends StatelessWidget {
  final List<Guest> guests;
  final List<RsvpResponse> responses;
  final VoidCallback onAddGuest;
  final ValueChanged<Guest> onEditGuest;
  final ValueChanged<String> onDeleteGuest;
  final ValueChanged<Guest> onSubmitRsvp;

  const _GuestListTab({
    required this.guests,
    required this.responses,
    required this.onAddGuest,
    required this.onEditGuest,
    required this.onDeleteGuest,
    required this.onSubmitRsvp,
  });

  @override
  Widget build(BuildContext context) {
    if (guests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👥', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 16),
            Text('No guests yet', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 8),
            Text('Add guests to track their RSVPs.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                )),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddGuest,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Add Guest'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      );
    }

    final responseMap = {for (final r in responses) r.guestId: r};

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: guests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final g = guests[i];
        final rsvp = responseMap[g.id];
        return _GuestCard(
          guest: g,
          rsvp: rsvp,
          onEdit: () => onEditGuest(g),
          onDelete: () => onDeleteGuest(g.id),
          onRsvp: () => onSubmitRsvp(g),
        );
      },
    );
  }
}

class _GuestCard extends StatelessWidget {
  final Guest guest;
  final RsvpResponse? rsvp;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onRsvp;

  const _GuestCard({
    required this.guest,
    required this.rsvp,
    required this.onEdit,
    required this.onDelete,
    required this.onRsvp,
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Text(_statusIcon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(guest.name, style: AppTextStyles.titleMedium),
                  if (guest.relation != null)
                    Text(guest.relation!,
                        style: AppTextStyles.caption.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                        )),
                  const SizedBox(height: 4),
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
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'rsvp') onRsvp();
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
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
                    value: 'edit',
                    child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit guest'),
                        contentPadding: EdgeInsets.zero,
                        dense: true)),
                const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                        leading: Icon(Icons.delete_outline,
                            color: AppColors.error),
                        title: Text('Remove',
                            style: TextStyle(color: AppColors.error)),
                        contentPadding: EdgeInsets.zero,
                        dense: true)),
              ],
              child: Icon(Icons.more_vert,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(153), size: 20),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        children: [
          Text(value,
              style: AppTextStyles.headlineMedium.copyWith(color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTextStyles.caption, textAlign: TextAlign.center),
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
          Text(label,
              style: AppTextStyles.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
              )),
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
              Text(meal, style: AppTextStyles.bodySmall),
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
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Text(_icon, style: const TextStyle(fontSize: 22)),
        title: Text(response.guestName, style: AppTextStyles.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
        trailing: Container(
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
                      child: GestureDetector(
                        onTap: () => setState(() => _status = s),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withAlpha(31)
                                : AppColors.surface,
                            border: Border.all(
                              color: selected ? color : AppColors.divider,
                              width: selected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
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
