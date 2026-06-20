import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/admin_provider.dart';
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
    final adminState = ref.watch(adminProvider);

    return Scaffold(
      backgroundColor: AppColors.adminPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: AppColors.divider,
        title: Text(
          'Content Moderation',
          style: AppTextStyles.headlineSmall
              .copyWith(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.adminIndigo,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.adminIndigo,
          indicatorWeight: 2,
          labelStyle:
              AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
          tabs: [
            Tab(
                text:
                    'Reviews (${adminState.flaggedReviews.length})'),
            Tab(
                text:
                    'Images (${adminState.flaggedImages.length})'),
            Tab(
                text:
                    'Messages (${adminState.flaggedMessages.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          // ── Reviews tab ──────────────────────────────────────
          _ReviewModerationList(
            reviews: adminState.flaggedReviews,
            onApprove: (id) {
              ref.read(adminProvider.notifier).approveReview(id);
              showWedSnackBar(context, 'Review approved',
                  type: SnackType.success);
            },
            onReject: (id) {
              ref.read(adminProvider.notifier).rejectReview(id);
              showWedSnackBar(context, 'Review removed',
                  type: SnackType.error);
            },
          ),

          // ── Images tab ───────────────────────────────────────
          _ImageModerationList(
            images: adminState.flaggedImages,
            onApprove: (id) {
              ref.read(adminProvider.notifier).approveImage(id);
              showWedSnackBar(context, 'Image approved',
                  type: SnackType.success);
            },
            onReject: (id) {
              ref.read(adminProvider.notifier).rejectImage(id);
              showWedSnackBar(context, 'Image removed',
                  type: SnackType.error);
            },
          ),

          // ── Messages tab ─────────────────────────────────────
          _MessageModerationList(
            messages: adminState.flaggedMessages,
            onApprove: (id) {
              ref.read(adminProvider.notifier).approveMessage(id);
              showWedSnackBar(context, 'Message cleared',
                  type: SnackType.success);
            },
            onReject: (id) {
              ref.read(adminProvider.notifier).rejectMessage(id);
              showWedSnackBar(context, 'Message removed',
                  type: SnackType.error);
            },
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
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
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
        style: AppTextStyles.caption
            .copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Review Moderation List ────────────────────────────────────────────────────

class _ReviewModerationList extends StatelessWidget {
  final List<FlaggedReview> reviews;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;

  const _ReviewModerationList({
    required this.reviews,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return const _EmptyModeration(
        icon: Icons.check_circle_rounded,
        message: 'All flagged reviews have been resolved.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reviews.length,
      itemBuilder: (_, i) {
        final review = reviews[i];
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
                      review.vendor,
                      style: AppTextStyles.titleMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _FlagChip(reason: review.flagReason),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(
                  5,
                  (j) => Icon(
                    j < review.rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 14,
                    color: AppColors.goldPremium,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                review.text,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: WedButton(
                      label: 'Remove',
                      variant: WedButtonVariant.destructive,
                      onPressed: () => onReject(review.id),
                      height: 38,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: WedButton(
                      label: 'Approve',
                      onPressed: () => onApprove(review.id),
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
  final List<FlaggedImage> images;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;

  const _ImageModerationList({
    required this.images,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const _EmptyModeration(
        icon: Icons.check_circle_rounded,
        message: 'All flagged images have been resolved.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: images.length,
      itemBuilder: (_, i) {
        final img = images[i];
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
              // Image placeholder
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  color: AppColors.adminNeutralBg,
                  child: Column(
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
                            style: AppTextStyles.titleMedium
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _FlagChip(reason: img.flagReason),
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
  final List<FlaggedMessage> messages;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onReject;

  const _MessageModerationList({
    required this.messages,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return const _EmptyModeration(
        icon: Icons.check_circle_rounded,
        message: 'All flagged messages have been resolved.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final msg = messages[i];
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
                        const Icon(Icons.person_outline,
                            size: 14,
                            color: AppColors.textSecondary),
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
                          child: Icon(Icons.arrow_forward,
                              size: 12,
                              color: AppColors.textHint),
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
                  _FlagChip(reason: msg.flagReason),
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
