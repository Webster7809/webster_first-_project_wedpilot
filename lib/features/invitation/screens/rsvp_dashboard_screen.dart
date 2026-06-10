import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/invitation.dart';
import '../../../providers/invitation_provider.dart';


class RsvpDashboardScreen extends ConsumerWidget {
  final String invitationId;
  const RsvpDashboardScreen({super.key, required this.invitationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rsvpsAsync = ref.watch(rsvpResponsesProvider(invitationId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('RSVP Dashboard')),
      body: rsvpsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (rsvps) {
          final attending = rsvps.where((r) => r.attending == AttendingStatus.yes).length;
          final declined = rsvps.where((r) => r.attending == AttendingStatus.no).length;
          final maybe = rsvps.where((r) => r.attending == AttendingStatus.maybe).length;
          final total = rsvps.fold(0, (sum, r) => sum + r.guestCount);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary row
              Row(
                children: [
                  Expanded(child: _RsvpStat(value: '$attending', label: 'Attending', color: AppColors.success)),
                  const SizedBox(width: 10),
                  Expanded(child: _RsvpStat(value: '$declined', label: 'Declined', color: AppColors.error)),
                  const SizedBox(width: 10),
                  Expanded(child: _RsvpStat(value: '$maybe', label: 'Maybe', color: AppColors.warning)),
                  const SizedBox(width: 10),
                  Expanded(child: _RsvpStat(value: '$total', label: 'Total\nGuests', color: AppColors.secondary)),
                ],
              ),
              const SizedBox(height: 20),

              Text('Guest Responses', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 12),
              ...rsvps.map((rsvp) => _RsvpCard(rsvp: rsvp)),

              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.send_outlined),
                label: const Text('Send Reminders to Pending'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondary,
                  side: const BorderSide(color: AppColors.secondary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RsvpStat extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _RsvpStat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 51)),
      ),
      child: Column(
        children: [
          Text(value, style: AppTextStyles.headlineMedium.copyWith(color: color)),
          Text(label, style: AppTextStyles.caption, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _RsvpCard extends StatelessWidget {
  final RsvpResponse rsvp;
  const _RsvpCard({required this.rsvp});

  Color get _color => switch (rsvp.attending) {
        AttendingStatus.yes => AppColors.success,
        AttendingStatus.no => AppColors.error,
        AttendingStatus.maybe => AppColors.warning,
      };

  String get _icon => switch (rsvp.attending) {
        AttendingStatus.yes => '✅',
        AttendingStatus.no => '❌',
        AttendingStatus.maybe => '🤔',
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Text(_icon, style: const TextStyle(fontSize: 24)),
        title: Text(rsvp.guestName, style: AppTextStyles.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (rsvp.guestCount > 1) Text('${rsvp.guestCount} guests', style: AppTextStyles.caption),
            if (rsvp.mealPreference != null) Text('Meal: ${rsvp.mealPreference}', style: AppTextStyles.caption),
            if (rsvp.message != null) Text('"${rsvp.message}"', style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 31),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            rsvp.attending.name[0].toUpperCase() + rsvp.attending.name.substring(1),
            style: AppTextStyles.caption.copyWith(color: _color, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
