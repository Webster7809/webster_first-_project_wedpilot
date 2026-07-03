import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/state/resource.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/vendor_own_provider.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_snack_bar.dart';

class AvailabilityCalendarScreen extends ConsumerStatefulWidget {
  const AvailabilityCalendarScreen({super.key});

  @override
  ConsumerState<AvailabilityCalendarScreen> createState() =>
      _AvailabilityCalendarScreenState();
}

class _AvailabilityCalendarScreenState
    extends ConsumerState<AvailabilityCalendarScreen> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    if (ref.watch(vendorOwnProvider).status == ResourceStatus.initial) {
      Future.microtask(() => ref.read(vendorOwnProvider.notifier).loadOwnVendorData());
    }
    final blockedDates = ref.watch(vendorBlockedDatesProvider);

    bool isBlocked(DateTime day) {
      final normalized = DateTime(day.year, day.month, day.day);
      return blockedDates.contains(normalized);
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        title: Text('Availability',
            style: AppTextStyles.headlineMedium.copyWith(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: WedButton(
            label: 'Save Availability',
            onPressed: () async {
              final error = await ref.read(vendorOwnProvider.notifier).persistBlockedDates();
              if (!context.mounted) return;
              if (error != null) {
                showWedSnackBar(context, error, type: SnackType.error);
              } else {
                showWedSnackBar(
                  context,
                  '${blockedDates.length} dates saved',
                  type: SnackType.success,
                );
              }
            },
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Card(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 730)),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                onDaySelected: (selected, focused) {
                  setState(() => _focusedDay = focused);
                  ref
                      .read(vendorOwnProvider.notifier)
                      .toggleBlockedDate(selected);
                },
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    if (isBlocked(day)) {
                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.error.withAlpha(38),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.error, width: 1.5),
                        ),
                        child: Center(
                          child: Text('${day.day}',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.error)),
                        ),
                      );
                    }
                    return null;
                  },
                ),
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(
                      color: AppColors.amber, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(
                      color: AppColors.forestGreen, shape: BoxShape.circle),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                            color: AppColors.error.withAlpha(38),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.error))),
                    const SizedBox(width: 6),
                    Text('Blocked / Unavailable',
                        style: AppTextStyles.bodySmall),
                    const SizedBox(width: 16),
                    Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                            color: AppColors.forestGreen,
                            shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('Today', style: AppTextStyles.bodySmall),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap a date to block/unblock it. Couples cannot inquire for blocked dates.',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Text('${blockedDates.length} dates blocked',
                    style: AppTextStyles.labelMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
