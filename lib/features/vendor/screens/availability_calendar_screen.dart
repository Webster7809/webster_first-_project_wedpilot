import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_snack_bar.dart';

class AvailabilityCalendarScreen extends StatefulWidget {
  const AvailabilityCalendarScreen({super.key});

  @override
  State<AvailabilityCalendarScreen> createState() => _AvailabilityCalendarScreenState();
}

class _AvailabilityCalendarScreenState extends State<AvailabilityCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  final Set<DateTime> _blockedDates = {};

  void _toggleDate(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    setState(() {
      if (_blockedDates.contains(normalized)) {
        _blockedDates.remove(normalized);
      } else {
        _blockedDates.add(normalized);
      }
    });
  }

  bool _isBlocked(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return _blockedDates.contains(normalized);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Availability Calendar')),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(16),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 730)),
              focusedDay: _focusedDay,
              calendarFormat: CalendarFormat.month,
              onDaySelected: (selected, focused) {
                setState(() => _focusedDay = focused);
                _toggleDate(selected);
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  if (_isBlocked(day)) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.error, width: 1.5),
                      ),
                      child: Center(
                        child: Text('${day.day}',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                      ),
                    );
                  }
                  return null;
                },
              ),
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                    color: AppColors.secondary, shape: BoxShape.circle),
                todayDecoration: BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 16, height: 16, decoration: BoxDecoration(color: AppColors.error.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: AppColors.error))),
                    const SizedBox(width: 8),
                    Text('Blocked / Unavailable', style: AppTextStyles.bodySmall),
                    const SizedBox(width: 20),
                    Container(width: 16, height: 16, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text('Today', style: AppTextStyles.bodySmall),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap a date to block/unblock it. Couples cannot inquire for blocked dates.',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                Text('${_blockedDates.length} dates blocked', style: AppTextStyles.labelMedium),
                const SizedBox(height: 16),
                WedButton(
                  label: 'Save Availability',
                  onPressed: () => showWedSnackBar(context, 'Availability saved!', type: SnackType.success),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
