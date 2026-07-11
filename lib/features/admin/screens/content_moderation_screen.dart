import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/admin_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/wed_button.dart';
import '../../../widgets/wed_snack_bar.dart';

class ContentModerationScreen extends ConsumerStatefulWidget {
  const ContentModerationScreen({super.key});

  @override
  ConsumerState<ContentModerationScreen> createState() =>
      _ContentModerationScreenState();
}

class _ContentModerationScreenState
    extends ConsumerState<ContentModerationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feedbackAsync = ref.watch(adminFeedbackProvider);
    final flaggedImagesAsync = ref.watch(adminFlaggedImagesProvider);
    final flaggedMessagesAsync = ref.watch(adminFlaggedMessagesProvider);
    final flaggedFeedbackCount =
        feedbackAsync.valueOrNull?.where((f) => f.isFlagged).length ?? 0;
    final flaggedImagesCount = flaggedImagesAsync.valueOrNull?.length ?? 0;
    final flaggedMessagesCount = flaggedMessagesAsync.valueOrNull?.length ?? 0;

    Future<void> setFeedbackFlag(
      String id,
      bool flagged,
      String successMessage, {
      String? reason,
    }) async {
      final token = ref.read(authProvider.notifier).accessToken;
      if (token == null) return;
      try {
        await AdminApiService.instance.flagFeedback(
          token,
          id,
          flagged: flagged,
          reason: reason,
        );
        ref.invalidate(adminFeedbackProvider);
        if (context.mounted) {
          showWedSnackBar(
            context,
            successMessage,
            type: flagged ? SnackType.error : SnackType.success,
          );
        }
      } on AdminApiException catch (e) {
        if (context.mounted) {
          showWedSnackBar(context, e.message, type: SnackType.error);
        }
      }
    }

    Future<void> moderateImage(
      String id,
      String action,
      String successMessage,
    ) async {
      final token = ref.read(authProvider.notifier).accessToken;
      if (token == null) return;
      try {
        await AdminApiService.instance.moderateImage(token, id, action: action);
        ref.invalidate(adminFlaggedImagesProvider);
        if (context.mounted) {
          showWedSnackBar(
            context,
            successMessage,
            type: action == 'approve' ? SnackType.success : SnackType.error,
          );
        }
      } on AdminApiException catch (e) {
        if (context.mounted) {
          showWedSnackBar(context, e.message, type: SnackType.error);
        }
      }
    }

    Future<void> flagWithReason(String id) async {
      final reasonCtrl = TextEditingController();
      final reason = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Flag feedback'),
          content: TextField(
            controller: reasonCtrl,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Reason (e.g. abusive comment)'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, reasonCtrl.text.trim()),
              child: const Text('Flag'),
            ),
          ],
        ),
      );
      if (reason == null) return;
      await setFeedbackFlag(
        id,
        true,
        'Feedback flagged and excluded from this vendor\'s score',
        reason: reason.isEmpty ? null : reason,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.adminPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: AppColors.divider,
        title: Text(
          'Content Moderation',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.adminIndigo,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.adminIndigo,
          indicatorWeight: 2,
          labelStyle: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w600,
          ),
          tabs: [
            Tab(text: 'Feedback ($flaggedFeedbackCount)'),
            Tab(text: 'Images ($flaggedImagesCount)'),
            Tab(text: 'Messages ($flaggedMessagesCount)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── Feedback tab ─────────────────────────────────────
          // Private couple→vendor feedback — never shown to other couples,
          // but readable by admins for policy enforcement. Unlike the other
          // tabs this lists everything (not just already-flagged items),
          // since nothing else can ever report it first.
          _FeedbackModerationList(
            feedbackAsync: feedbackAsync,
            onFlag: flagWithReason,
            onUnflag: (id) => setFeedbackFlag(id, false, 'Feedback restored to this vendor\'s score'),
            onRefresh: () async => ref.invalidate(adminFeedbackProvider),
          ),

          // ── Images tab ───────────────────────────────────────
          _ImageModerationList(
            imagesAsync: flaggedImagesAsync,
            onApprove: (id) => moderateImage(id, 'approve', 'Image approved'),
            onReject: (id) => moderateImage(id, 'reject', 'Image removed'),
            onRefresh: () async => ref.invalidate(adminFlaggedImagesProvider),
          ),

          // ── Messages tab ─────────────────────────────────────
          // Always empty today — no messaging system exists yet to flag from.
          _MessageModerationList(
            messagesAsync: flaggedMessagesAsync,
            onApprove: (_) {},
            onReject: (_) {},
            onRefresh: () async => ref.invalidate(adminFlaggedMessagesProvider),
          ),
        ],
      ),
    );
  }
}

// ── Shared empty state ────────────────────────────────────────────────────────

class _EmptyModeration extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyModeration({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.success),
          const SizedBox(height: 16),
          Text('All clear!', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared error state ────────────────────────────────────────────────────────

class _ModerationError extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _ModerationError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text('Could not load this queue.', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 6),
          Text(
            'Check your connection, then pull down or retry.',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

// ── Shared async list scaffold ────────────────────────────────────────────────
// Handles loading/error/empty/data for every moderation tab uniformly, with
// pull-to-refresh available even on the loading/error/empty states.

class _ModerationListView<T> extends StatelessWidget {
  final AsyncValue<List<T>> asyncValue;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final IconData emptyIcon;
  final String emptyMessage;
  final Future<void> Function() onRefresh;

  const _ModerationListView({
    required this.asyncValue,
    required this.itemBuilder,
    required this.emptyIcon,
    required this.emptyMessage,
    required this.onRefresh,
  });

  Widget _scrollableCenter(Widget child) => LayoutBuilder(
        builder: (context, constraints) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: constraints.maxHeight,
              child: child,
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: asyncValue.when(
        loading: () => _scrollableCenter(
          const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stackTrace) => _scrollableCenter(
          _ModerationError(onRetry: onRefresh),
        ),
        data: (items) => items.isEmpty
            ? _scrollableCenter(
                _EmptyModeration(icon: emptyIcon, message: emptyMessage),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (ctx, i) => itemBuilder(ctx, items[i]),
              ),
      ),
    );
  }
}

// ── Shared flag chip ──────────────────────────────────────────────────────────

class _FlagChip extends StatelessWidget {
  final String reason;
  const _FlagChip({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.adminRedBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Flagged: $reason',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ── Feedback Moderation List ──────────────────────────────────────────────────
// Private couple→vendor feedback. Every row is visible to admins (per the
// access model — only the owning vendor and admins can read it), not just
// previously-flagged ones, since there's no way for another couple to ever
// report it first.

class _FeedbackModerationList extends StatelessWidget {
  final AsyncValue<List<AdminVendorFeedback>> feedbackAsync;
  final ValueChanged<String> onFlag;
  final ValueChanged<String> onUnflag;
  final Future<void> Function() onRefresh;

  const _FeedbackModerationList({
    required this.feedbackAsync,
    required this.onFlag,
    required this.onUnflag,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return _ModerationListView<AdminVendorFeedback>(
      asyncValue: feedbackAsync,
      onRefresh: onRefresh,
      emptyIcon: Icons.forum_outlined,
      emptyMessage: 'No feedback has been submitted yet.',
      itemBuilder: (context, feedback) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${feedback.vendor} · ${feedback.coupleName}',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (feedback.isFlagged) ...[
                    const SizedBox(width: 8),
                    Flexible(child: _FlagChip(reason: feedback.flagReason ?? 'Flagged')),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(
                  5,
                  (j) => Icon(
                    j < feedback.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: AppColors.goldPremium,
                  ),
                ),
              ),
              if (feedback.comment != null && feedback.comment!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  feedback.comment!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: feedback.isFlagged
                        ? WedButton(
                            label: 'Unflag',
                            onPressed: () => onUnflag(feedback.id),
                            height: 38,
                          )
                        : WedButton(
                            label: 'Flag',
                            variant: WedButtonVariant.destructive,
                            onPressed: () => onFlag(feedback.id),
                            height: 38,
                          ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Image Moderation List ─────────────────────────────────────────────────────

class _ImageModerationList extends StatelessWidget {
  final AsyncValue<List<FlaggedImage>> imagesAsync;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;
  final Future<void> Function() onRefresh;

  const _ImageModerationList({
    required this.imagesAsync,
    required this.onApprove,
    required this.onReject,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return _ModerationListView<FlaggedImage>(
      asyncValue: imagesAsync,
      onRefresh: onRefresh,
      emptyIcon: Icons.check_circle_rounded,
      emptyMessage: 'All flagged images have been resolved.',
      itemBuilder: (context, img) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Container(
                  height: 200,
                  width: double.infinity,
                  color: AppColors.adminNeutralBg,
                  child: img.url.isNotEmpty
                      ? Image.network(
                          img.thumbnailUrl ?? img.url,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 36,
                              color: AppColors.textHint,
                            ),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          },
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 36,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              img.category,
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            img.vendor,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(child: _FlagChip(reason: img.flagReason)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: WedButton(
                            label: 'Remove',
                            variant: WedButtonVariant.destructive,
                            onPressed: () => onReject(img.id),
                            height: 38,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: WedButton(
                            label: 'Approve',
                            onPressed: () => onApprove(img.id),
                            height: 38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Message Moderation List ───────────────────────────────────────────────────

class _MessageModerationList extends StatelessWidget {
  final AsyncValue<List<FlaggedMessage>> messagesAsync;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;
  final Future<void> Function() onRefresh;

  const _MessageModerationList({
    required this.messagesAsync,
    required this.onApprove,
    required this.onReject,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return _ModerationListView<FlaggedMessage>(
      asyncValue: messagesAsync,
      onRefresh: onRefresh,
      emptyIcon: Icons.check_circle_rounded,
      emptyMessage: 'All flagged messages have been resolved.',
      itemBuilder: (context, msg) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sender → Recipient
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            msg.sender,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            msg.recipient,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(child: _FlagChip(reason: msg.flagReason)),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.adminPage,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${msg.excerpt}"',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: WedButton(
                      label: 'Remove',
                      variant: WedButtonVariant.destructive,
                      onPressed: () => onReject(msg.id),
                      height: 38,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: WedButton(
                      label: 'Clear Flag',
                      onPressed: () => onApprove(msg.id),
                      height: 38,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
