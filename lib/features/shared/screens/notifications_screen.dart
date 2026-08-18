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
import '../../../widgets/wed_skeleton.dart';

// Notification types that deep-link somewhere beyond just marking read —
// everything else keeps the original mark-read-only tap behavior.
const _kDeepLinkTypes = {'rate_vendor', 'booking_accepted', 'booking_declined'};

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  static (IconData, Color, Color) _presentation(String type) {
    switch (type) {
      case 'message':
        return (Icons.chat_bubble_outlined, AppColors.forestGreen, AppColors.adminGreenBg);
      case 'budget_alert':
        return (Icons.account_balance_wallet_outlined, AppColors.warning, AppColors.warningBg);
      case 'vendor_verification':
        return (Icons.verified_user_outlined, AppColors.success, AppColors.successBg);
      case 'booking_accepted':
        return (Icons.event_available_outlined, AppColors.success, AppColors.successBg);
      case 'booking_declined':
        return (Icons.event_busy_outlined, AppColors.warning, AppColors.warningBg);
      case 'rate_vendor':
        return (Icons.star_outlined, AppColors.amber, AppColors.adminAmberBg);
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

  /// Swipe-to-dismiss on a single row. The tile has already animated itself
  /// off-screen by the time this runs (Dismissible's contract), so a failure
  /// here can't just silently no-op — the provider is invalidated either way
  /// to reconcile the list with whatever the backend actually has, and the
  /// couple is told if the delete didn't really happen.
  Future<void> _delete(WidgetRef ref, BuildContext context, String notifId) async {
    final token = ref.read(authProvider.notifier).accessToken;
    if (token == null) return;
    try {
      await NotificationApiService.instance.deleteNotification(token, notifId);
    } on NotificationApiException catch (e) {
      if (context.mounted) showWedSnackBar(context, e.message, type: SnackType.error);
    } finally {
      ref.invalidate(notificationsProvider);
    }
  }

  Future<void> _clearRead(WidgetRef ref, BuildContext context) async {
    final token = ref.read(authProvider.notifier).accessToken;
    if (token == null) return;
    try {
      await NotificationApiService.instance.clearRead(token);
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
    final hasRead = notifications.any((n) => n.isRead);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        backgroundColor: AppColors.forestGreen,
        foregroundColor: Colors.white,
        actions: [
          // A single overflow menu rather than two AppBar-level text buttons —
          // "Mark all read" plus a second label was already close to wrapping
          // on a narrow phone (see test/messages_overflow_test.dart's 320px
          // case elsewhere in this app), and a third action here would tip it.
          PopupMenuButton<VoidCallback>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (action) => action(),
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: unread > 0,
                value: () => _markAllRead(ref, context),
                child: const Text('Mark all read'),
              ),
              PopupMenuItem(
                enabled: hasRead,
                value: () => _clearRead(ref, context),
                child: const Text('Clear read notifications'),
              ),
            ],
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const WedListSkeleton(rows: 6),
        error: (error, stack) => Center(
          child: Text(
            'Unable to load notifications.',
            style: AppTextStyles.bodyLarge
                .copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        data: (_) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none,
                      size: 56,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text('No notifications yet', style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 6),
                  Text(
                    "We'll let you know when something needs your attention.",
                    style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
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
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
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
                    return Dismissible(
                      key: ValueKey(n.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        color: AppColors.error,
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      onDismissed: (_) => _delete(ref, context, n.id),
                      child: _NotificationTile(
                        notification: n,
                        presentation: _presentation(n.type),
                        onTap: onTap,
                      ),
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
