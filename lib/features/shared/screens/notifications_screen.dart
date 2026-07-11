import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/notification_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/format_utils.dart';
import '../../../models/notification_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../widgets/wed_snack_bar.dart';

// Notification types that deep-link somewhere beyond just marking read —
// everything else keeps the original mark-read-only tap behavior.
const _kDeepLinkTypes = {'rate_vendor', 'booking_accepted', 'booking_declined'};

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static (IconData, Color, Color) _presentation(String type) {
    switch (type) {
      case 'message':
        return (Icons.chat_bubble_outline_rounded, AppColors.forestGreen, AppColors.adminGreenBg);
      case 'budget_alert':
        return (Icons.account_balance_wallet_outlined, AppColors.warning, AppColors.warningBg);
      case 'vendor_verification':
        return (Icons.verified_user_outlined, AppColors.success, AppColors.successBg);
      case 'booking_accepted':
        return (Icons.event_available_outlined, AppColors.success, AppColors.successBg);
      case 'booking_declined':
        return (Icons.event_busy_outlined, AppColors.warning, AppColors.warningBg);
      case 'rate_vendor':
        return (Icons.star_outline_rounded, AppColors.amber, AppColors.adminAmberBg);
      default:
        return (Icons.notifications_outlined, AppColors.amber, AppColors.adminAmberBg);
    }
  }

  Future<void> _markRead(WidgetRef ref, BuildContext context, String notifId) async {
    final token = ref.read(authProvider.notifier).accessToken;
    if (token == null) return;
    try {
      await NotificationApiService.instance.markRead(token, notifId);
      ref.invalidate(notificationsProvider);
    } on NotificationApiException catch (e) {
      if (context.mounted) showWedSnackBar(context, e.message, type: SnackType.error);
    }
  }

  Future<void> _handleTap(WidgetRef ref, BuildContext context, NotificationModel n) async {
    if (!n.isRead) await _markRead(ref, context, n.id);
    if (!context.mounted) return;
    switch (n.type) {
      case 'rate_vendor':
        context.push(AppRoutes.coupleFeedbackNew, extra: n.entityId);
        break;
      case 'booking_accepted':
      case 'booking_declined':
        if (n.entityId != null) context.push('/couple/vendors/${n.entityId}');
        break;
    }
  }

  Future<void> _markAllRead(WidgetRef ref, BuildContext context) async {
    final token = ref.read(authProvider.notifier).accessToken;
    if (token == null) return;
    try {
      await NotificationApiService.instance.markAllRead(token);
      ref.invalidate(notificationsProvider);
    } on NotificationApiException catch (e) {
      if (context.mounted) showWedSnackBar(context, e.message, type: SnackType.error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final notifications = notificationsAsync.valueOrNull ?? [];
    final unread = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: unread > 0 ? () => _markAllRead(ref, context) : null,
            child: Text(
              'Mark all read',
              style: AppTextStyles.labelMedium.copyWith(
                color: unread > 0 ? AppColors.amber : AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Unable to load notifications.',
            style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
          ),
        ),
        data: (_) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.notifications_none_rounded,
                      size: 56, color: AppColors.textHint),
                  const SizedBox(height: 12),
                  Text('No notifications yet', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    "We'll let you know when something needs your attention.",
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return Column(
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
                  itemCount: notifications.length,
                  separatorBuilder: (context, i) => Divider(
                    height: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  itemBuilder: (_, i) {
                    final n = notifications[i];
                    final deepLinks = _kDeepLinkTypes.contains(n.type);
                    final onTap = deepLinks
                        ? () => _handleTap(ref, context, n)
                        : (n.isRead ? null : () => _markRead(ref, context, n.id));
                    return _NotificationTile(
                      notification: n,
                      presentation: _presentation(n.type),
                      onTap: onTap,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final (IconData, Color, Color) presentation;
  final VoidCallback? onTap;

  const _NotificationTile({
    required this.notification,
    required this.presentation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final n = notification;
    final (icon, iconColor, iconBg) = presentation;

    return ListTile(
      onTap: onTap,
      tileColor: n.isRead ? null : AppColors.secondary.withAlpha(10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
        child: Icon(icon, size: 20, color: iconColor),
      ),
      title: Text(
        n.title,
        style: AppTextStyles.titleMedium.copyWith(
          fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600,
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
            fmtRelativeTime(n.sentAt),
            style: AppTextStyles.caption.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
      trailing: n.isRead
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
