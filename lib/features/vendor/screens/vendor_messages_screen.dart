import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/messaging_provider.dart';
import '../../../widgets/wed_avatar.dart';
import '../../../widgets/wed_empty_state.dart';
import '../../../widgets/wed_skeleton.dart';

class VendorMessagesScreen extends ConsumerWidget {
  const VendorMessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final convsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        title: Text('Messages',
            style: AppTextStyles.headlineMedium.copyWith(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: convsAsync.when(
        loading: () => const WedListSkeleton(rows: 6),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (convs) {
          if (convs.isEmpty) {
            return const WedEmptyState(
              icon: Icons.chat_bubble_outlined,
              title: 'No messages yet',
              message: 'Conversations with couples will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: convs.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (_, i) {
              final conv = convs[i];
              final name = conv.coupleName ?? 'Couple';
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                leading: WedAvatar(imageUrl: conv.coupleAvatarUrl, name: name, radius: 24),
                title: Text(name,
                    style: AppTextStyles.titleMedium
                        .copyWith(color: AppColors.forestGreen),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                subtitle: Text(
                    conv.lastMessageText?.isNotEmpty == true
                        ? conv.lastMessageText!
                        : 'No messages yet — tap to start chatting',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: conv.lastMessageText?.isNotEmpty == true
                            ? AppColors.textSecondary
                            : AppColors.textHint,
                        fontStyle: conv.lastMessageText?.isNotEmpty == true
                            ? FontStyle.normal
                            : FontStyle.italic),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                trailing: conv.unreadCount > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${conv.unreadCount}',
                            style: const TextStyle(
                                color: AppColors.textOnSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      )
                    : null,
                onTap: () => context.push('/vendor/messages/${conv.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
