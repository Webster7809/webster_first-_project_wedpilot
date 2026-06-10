import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  final _notifications = const [
    {'icon': '💬', 'title': 'New message from Blossom Photography', 'body': 'Thank you for your inquiry! We\'d love to work with you.', 'time': '2h ago', 'read': false},
    {'icon': '💰', 'title': 'Budget alert', 'body': 'Venue category is at 90% of your allocation.', 'time': '5h ago', 'read': false},
    {'icon': '⭐', 'title': 'Vendor matched!', 'body': 'We found 3 new photographers matching your budget and style.', 'time': '1d ago', 'read': true},
    {'icon': '✅', 'title': 'Profile verified', 'body': 'Your account has been fully verified.', 'time': '2d ago', 'read': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text('Mark all read', style: AppTextStyles.labelMedium.copyWith(color: AppColors.secondary)),
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: _notifications.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final notif = _notifications[i];
          return Container(
            color: notif['read'] as bool ? null : AppColors.secondary.withValues(alpha: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 102),
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text(notif['icon'] as String, style: const TextStyle(fontSize: 20))),
              ),
              title: Text(
                notif['title'] as String,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: notif['read'] as bool ? FontWeight.normal : FontWeight.w600,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notif['body'] as String,
                      style: AppTextStyles.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text(notif['time'] as String, style: AppTextStyles.caption),
                ],
              ),
              trailing: notif['read'] as bool ? null : Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
              ),
            ),
          );
        },
      ),
    );
  }
}
