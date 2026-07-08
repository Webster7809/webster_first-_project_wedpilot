import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/invitation.dart';
import '../../../providers/invitation_provider.dart';
import '../../../widgets/wed_card.dart';

class AdminInvitationTemplatesScreen extends ConsumerWidget {
  const AdminInvitationTemplatesScreen({super.key});

  Widget _buildPreview(InvitationTemplate template) {
    if (template.previewUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          template.previewUrl,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 80,
            height: 80,
            color: AppColors.adminNeutralBg,
            child: const Icon(
              Icons.image_not_supported_outlined,
              size: 28,
              color: AppColors.textHint,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.adminNeutralBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.image_outlined,
        size: 28,
        color: AppColors.textHint,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(invitationTemplatesProvider);

    return Scaffold(
      backgroundColor: AppColors.adminPage,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: AppColors.divider,
        title: Text(
          'Invitation templates',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: templatesAsync.when(
        data: (templates) {
          if (templates.isEmpty) {
            return Center(
              child: Text(
                'No invitation templates are available.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemCount: templates.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available templates',
                      style: AppTextStyles.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This list reflects the invitation templates available to couples when creating an invitation. Premium templates are marked for reference.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              }

              final template = templates[index - 1];
              return WedCard(
                child: Row(
                  children: [
                    _buildPreview(template),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(template.name, style: AppTextStyles.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            'Theme: ${template.theme}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  6,
                                  10,
                                  6,
                                ),
                                decoration: BoxDecoration(
                                  color: template.isActive
                                      ? AppColors.adminGreenBg
                                      : AppColors.adminNeutralBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  template.isActive ? 'Active' : 'Inactive',
                                  style: AppTextStyles.caption.copyWith(
                                    color: template.isActive
                                        ? AppColors.adminGreen
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (template.isPremium)
                                Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    10,
                                    6,
                                    10,
                                    6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.adminAmberBg,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Premium',
                                    style: AppTextStyles.caption.copyWith(
                                      color: AppColors.adminAmber,
                                      fontWeight: FontWeight.w600,
                                    ),
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
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Unable to load invitation templates.',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
