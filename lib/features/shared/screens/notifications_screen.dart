import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unread = _notifications.where((n) => !n.read).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'Mark all read',
              style: AppTextStyles.labelMedium.copyWith(color: AppColors.amber),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (unread > 0)
            Container(
              width: double.infinity,
              color: AppColors.amber.withAlpha(20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                '$unread unread notification${unread == 1 ? '' : 's'}',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.amber),
              ),
            ),
          Expanded(
            child: ListView.separated(
              itemCount: _notifications.length,
              separatorBuilder: (context, i) => Divider(
                height: 1,
                color: cs.outlineVariant,
              ),
              itemBuilder: (_, i) {
                final n = _notifications[i];
                return _NotificationTile(notification: n);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifData {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String body;
  final String time;
  final bool read;

  const _NotifData({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.body,
    required this.time,
    required this.read,
  });
}

const _notifications = [
  _NotifData(
    icon: Icons.chat_bubble_outline_rounded,
    iconColor: AppColors.forestGreen,
    iconBg: AppColors.adminGreenBg,
    title: 'New message from Blossom Photography',
    body: "Thank you for your inquiry! We'd love to work with you.",
    time: '2h ago',
    read: false,
  ),
  _NotifData(
    icon: Icons.account_balance_wallet_outlined,
    iconColor: AppColors.warning,
    iconBg: AppColors.warningBg,
    title: 'Budget alert',
    body: 'Venue category is at 90% of your allocation.',
    time: '5h ago',
    read: false,
  ),
  _NotifData(
    icon: Icons.star_outline_rounded,
    iconColor: AppColors.amber,
    iconBg: AppColors.adminAmberBg,
    title: 'Vendor matched!',
    body: 'We found 3 new photographers matching your budget and style.',
    time: '1d ago',
    read: true,
  ),
  _NotifData(
    icon: Icons.verified_user_outlined,
    iconColor: AppColors.success,
    iconBg: AppColors.successBg,
    title: 'Profile verified',
    body: 'Your account has been fully verified.',
    time: '2d ago',
    read: true,
  ),
];

class _NotificationTile extends StatelessWidget {
  final _NotifData notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final n = notification;

    return ListTile(
      tileColor: n.read ? null : AppColors.secondary.withAlpha(10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: n.iconBg,
          shape: BoxShape.circle,
        ),
        child: Icon(n.icon, size: 20, color: n.iconColor),
      ),
      title: Text(
        n.title,
        style: AppTextStyles.titleMedium.copyWith(
          fontWeight: n.read ? FontWeight.normal : FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            n.body,
            style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            n.time,
            style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
      trailing: n.read
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
            ),
    );
  }
}
