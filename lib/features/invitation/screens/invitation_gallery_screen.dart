import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../providers/invitation_provider.dart';

class InvitationGalleryScreen extends ConsumerWidget {
  const InvitationGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(invitationTemplatesProvider);
    final myInvitations = ref.watch(invitationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Invitations')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // My invitations
          if (myInvitations.isNotEmpty) ...[
            Text('My Invitations', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 12),
            ...myInvitations.map((inv) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                      child: const Center(child: Text('💌', style: TextStyle(fontSize: 24))),
                    ),
                    title: Text(inv.title, style: AppTextStyles.titleMedium),
                    subtitle: Text(inv.status.name.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(
                            color: inv.status.name == 'published' ? AppColors.success : AppColors.textSecondary)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                    onTap: () => context.push('/couple/invitations/editor?id=${inv.id}'),
                  ),
                )),
            const SizedBox(height: 20),
          ],

          // Template gallery
          Text('Choose a Template', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 4),
          Text('Tap any template to start designing your invitation',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          templatesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (templates) => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: templates.length,
              itemBuilder: (_, i) {
                final template = templates[i];
                return _TemplateCard(
                  template: template,
                  onTap: () {
                    ref.read(invitationsProvider.notifier).create(template.id, 'My Wedding Invitation');
                    context.push('/couple/invitations/editor');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final dynamic template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  Color get _bgColor {
    return switch (template.theme as String) {
      'romantic' => const Color(0xFFF8BBD9),
      'modern' => const Color(0xFFF0F0F0),
      'royal' => const Color(0xFF1A1A4E),
      'rustic' => const Color(0xFF8B6914).withValues(alpha: 77),
      'boho' => const Color(0xFFE8D5B7),
      'beach' => const Color(0xFF006994).withValues(alpha: 77),
      'celestial' => const Color(0xFF0D0D2B),
      'african' => const Color(0xFFFFC300).withValues(alpha: 77),
      'islamic' => const Color(0xFF006400).withValues(alpha: 51),
      'indian' => const Color(0xFFFF7722).withValues(alpha: 51),
      _ => const Color(0xFFF8BBD9),
    };
  }

  String get _emoji {
    return switch (template.theme as String) {
      'romantic' => '🌸',
      'modern' => '◻️',
      'royal' => '👑',
      'rustic' => '🌿',
      'boho' => '🪶',
      'beach' => '🌊',
      'celestial' => '✨',
      'african' => '🌍',
      'islamic' => '🕌',
      'indian' => '🪔',
      _ => '💌',
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    template.name as String,
                    style: AppTextStyles.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          if (template.isPremium as bool)
            Positioned(
              top: 8, right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.goldPremium,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('PRO', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}
