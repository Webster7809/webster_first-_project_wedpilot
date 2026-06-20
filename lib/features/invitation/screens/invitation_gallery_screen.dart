import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models/invitation.dart';
import '../../../providers/invitation_provider.dart';

class InvitationGalleryScreen extends ConsumerWidget {
  const InvitationGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(invitationTemplatesProvider);
    final myInvitations = ref.watch(invitationsProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cols = screenWidth >= 900 ? 4 : screenWidth >= 600 ? 3 : 2;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App bar ───────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 96,
            pinned: true,
            backgroundColor: AppColors.forestGreen,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.forestGreen, Color(0xFF2A5C3F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Wedding Invitations',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Choose a design that reflects your love story',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.white.withAlpha(217),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── My invitations + section header ───────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (myInvitations.isNotEmpty) ...[
                  _GallerySection(
                      title: 'My Invitations', icon: Icons.bookmark_rounded),
                  const SizedBox(height: 8),
                  ...myInvitations.map((inv) => _MyInvitationCard(
                        invitation: inv,
                        onTap: () => context
                            .push('/couple/invitations/editor?id=${inv.id}'),
                      )),
                  const SizedBox(height: 20),
                ],
                _GallerySection(
                  title: 'Choose Your Design',
                  icon: Icons.style_rounded,
                ),
                const SizedBox(height: 3),
                Text(
                  'Curated themes with matching fonts and colour palettes',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                  ),
                ),
                const SizedBox(height: 12),
              ]),
            ),
          ),

          // ── Template grid (native SliverGrid — no shrinkWrap anti-pattern)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: templatesAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Error: $e'),
                  ),
                ),
              ),
              data: (templates) => SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  // Fixed card height keeps design consistent across screen widths
                  mainAxisExtent: 220,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final tpl = templates[i];
                    return _TemplateCard(
                      template: tpl,
                      onTap: () {
                        final newId = ref
                            .read(invitationsProvider.notifier)
                            .create(tpl.id, 'My Wedding Invitation');
                        context.push('/couple/invitations/editor?id=$newId');
                      },
                    );
                  },
                  childCount: templates.length,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gallery section header ──────────────────────────────────────────────────

class _GallerySection extends StatelessWidget {
  final String title;
  final IconData icon;
  const _GallerySection({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.secondary),
        const SizedBox(width: 6),
        Text(title, style: AppTextStyles.headlineSmall),
      ],
    );
  }
}

// ── My invitation card ──────────────────────────────────────────────────────

class _MyInvitationCard extends StatelessWidget {
  final Invitation invitation;
  final VoidCallback onTap;
  const _MyInvitationCard({required this.invitation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final published = invitation.status == InvitationStatus.published;
    final customData = invitation.customData;
    final title = customData['coupleName'] as String? ?? invitation.title;
    final date = customData['date'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Gradient swatch
                Container(
                  width: 38,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF06292), Color(0xFFBA68C8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.favorite,
                      color: Colors.white, size: 15),
                ),
                const SizedBox(width: 12),
                // Title + meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _StatusBadge(published: published),
                          if (date.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.calendar_today_outlined,
                                size: 10, color: AppColors.textSecondary),
                            const SizedBox(width: 3),
                            Text(date, style: AppTextStyles.caption),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right_rounded,
                    size: 16, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool published;
  const _StatusBadge({required this.published});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: published
            ? AppColors.info.withAlpha(31)
            : AppColors.warning.withAlpha(31),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            published ? Icons.share_outlined : Icons.edit_outlined,
            size: 9,
            color: published ? AppColors.info : AppColors.warning,
          ),
          const SizedBox(width: 3),
          Text(
            published ? 'Shared' : 'Draft',
            style: AppTextStyles.caption.copyWith(
              color: published ? AppColors.info : AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Theme metadata ──────────────────────────────────────────────────────────

class _ThemeMeta {
  final List<Color> gradient;
  final Color textColor;
  final Color accentColor;
  final String tagline;
  final List<_DecoElement> decor;

  const _ThemeMeta({
    required this.gradient,
    required this.textColor,
    required this.accentColor,
    required this.tagline,
    this.decor = const [],
  });
}

class _DecoElement {
  final String symbol;
  final double size;
  final Alignment alignment;
  final double opacity;
  const _DecoElement(this.symbol, this.size, this.alignment,
      {this.opacity = 0.25});
}

_ThemeMeta _metaFor(String theme) {
  return switch (theme) {
    'romantic' => _ThemeMeta(
        gradient: const [Color(0xFFFFF0F5), Color(0xFFFFC1D9)],
        textColor: const Color(0xFF880E4F),
        accentColor: const Color(0xFFF06292),
        tagline: 'Soft florals & romance',
        decor: [
          _DecoElement('🌸', 44, Alignment.topRight, opacity: 0.32),
          _DecoElement('🌷', 28, Alignment.bottomLeft, opacity: 0.28),
        ],
      ),
    'modern' => _ThemeMeta(
        gradient: const [Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
        textColor: const Color(0xFF212121),
        accentColor: const Color(0xFF424242),
        tagline: 'Clean lines & elegance',
        decor: [
          _DecoElement('◼', 34, Alignment.topRight, opacity: 0.10),
          _DecoElement('◻', 20, Alignment.bottomLeft, opacity: 0.08),
        ],
      ),
    'royal' => _ThemeMeta(
        gradient: const [Color(0xFF1A1A4E), Color(0xFF3F1DCB)],
        textColor: const Color(0xFFFFD700),
        accentColor: const Color(0xFFD4A854),
        tagline: 'Regal & grand',
        decor: [
          _DecoElement('👑', 40, Alignment.topRight, opacity: 0.42),
          _DecoElement('✦', 26, Alignment.bottomLeft, opacity: 0.32),
        ],
      ),
    'rustic' => _ThemeMeta(
        gradient: const [Color(0xFFF5ECD7), Color(0xFFDEB887)],
        textColor: const Color(0xFF4E342E),
        accentColor: const Color(0xFF795548),
        tagline: 'Earthy & botanical',
        decor: [
          _DecoElement('🌿', 42, Alignment.topRight, opacity: 0.38),
          _DecoElement('🍃', 26, Alignment.bottomLeft, opacity: 0.32),
        ],
      ),
    'boho' => _ThemeMeta(
        gradient: const [Color(0xFFFFF8EE), Color(0xFFE8D5B7)],
        textColor: const Color(0xFF5D4037),
        accentColor: const Color(0xFFBF8A68),
        tagline: 'Free-spirited & dreamy',
        decor: [
          _DecoElement('🪶', 40, Alignment.topRight, opacity: 0.42),
          _DecoElement('☽', 28, Alignment.bottomLeft, opacity: 0.28),
        ],
      ),
    'beach' => _ThemeMeta(
        gradient: const [Color(0xFFE0F7FF), Color(0xFF80DEEA)],
        textColor: const Color(0xFF01579B),
        accentColor: const Color(0xFF0288D1),
        tagline: 'Breezy ocean vibes',
        decor: [
          _DecoElement('🌊', 40, Alignment.topRight, opacity: 0.38),
          _DecoElement('🐚', 26, Alignment.bottomLeft, opacity: 0.32),
        ],
      ),
    'celestial' => _ThemeMeta(
        gradient: const [Color(0xFF0D0D2B), Color(0xFF1A0533)],
        textColor: const Color(0xFFE8C9FF),
        accentColor: const Color(0xFFAA88FF),
        tagline: 'Stars & mystical nights',
        decor: [
          _DecoElement('✨', 38, Alignment.topRight, opacity: 0.52),
          _DecoElement('🌙', 26, Alignment.bottomLeft, opacity: 0.46),
        ],
      ),
    'african' => _ThemeMeta(
        gradient: const [Color(0xFFFFF3CD), Color(0xFFFFCC02)],
        textColor: const Color(0xFF4A2000),
        accentColor: const Color(0xFFE65100),
        tagline: 'Vibrant & cultural',
        decor: [
          _DecoElement('🌍', 40, Alignment.topRight, opacity: 0.42),
          _DecoElement('🥁', 26, Alignment.bottomLeft, opacity: 0.32),
        ],
      ),
    'islamic' => _ThemeMeta(
        gradient: const [Color(0xFFE8F5E9), Color(0xFFA5D6A7)],
        textColor: const Color(0xFF1B5E20),
        accentColor: const Color(0xFF2E7D32),
        tagline: 'Graceful & sacred',
        decor: [
          _DecoElement('☪', 40, Alignment.topRight, opacity: 0.32),
          _DecoElement('🕌', 26, Alignment.bottomLeft, opacity: 0.28),
        ],
      ),
    'indian' => _ThemeMeta(
        gradient: const [Color(0xFFFFF8E1), Color(0xFFFFCC80)],
        textColor: const Color(0xFF7B1F00),
        accentColor: const Color(0xFFE64A19),
        tagline: 'Vibrant & festive',
        decor: [
          _DecoElement('🪔', 40, Alignment.topRight, opacity: 0.42),
          _DecoElement('🌺', 26, Alignment.bottomLeft, opacity: 0.38),
        ],
      ),
    _ => _ThemeMeta(
        gradient: const [Color(0xFFFFF0F5), Color(0xFFFFC1D9)],
        textColor: const Color(0xFF880E4F),
        accentColor: const Color(0xFFF06292),
        tagline: 'Beautiful & elegant',
      ),
  };
}

// ── Template card ───────────────────────────────────────────────────────────
// Compact portrait card: gradient preview (top 72%) + white label (bottom 28%).
// Card height is fixed via mainAxisExtent in the grid delegate, so no overflow.

class _TemplateCard extends StatelessWidget {
  final InvitationTemplate template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = _metaFor(template.theme);
    final isDark = meta.gradient.first.computeLuminance() < 0.15;
    final isPremium = template.isPremium;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shadowColor: Colors.black.withAlpha(36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Gradient invitation preview ────────────────────────────
            Expanded(
              flex: 72,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: meta.gradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Decorative theme elements
                    for (final d in meta.decor)
                      Positioned.fill(
                        child: Align(
                          alignment: d.alignment,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Opacity(
                              opacity: d.opacity,
                              child: Text(
                                d.symbol,
                                style: TextStyle(fontSize: d.size * 0.44),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Sample invitation content — centred
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'A & B',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: meta.textColor,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Container(
                            width: 22,
                            height: 0.8,
                            color: meta.accentColor.withAlpha(153),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            'WEDDING',
                            style: GoogleFonts.inter(
                              fontSize: 6.5,
                              fontWeight: FontWeight.w600,
                              color: meta.textColor.withAlpha(128),
                              letterSpacing: 2.2,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Thin border on light-background themes
                    if (!isDark)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: meta.accentColor.withAlpha(38),
                              width: 0.8,
                            ),
                          ),
                        ),
                      ),

                    // PRO badge
                    if (isPremium)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(6, 2.5, 6, 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD4A854),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_rounded,
                                  color: Colors.white, size: 8),
                              SizedBox(width: 2),
                              Text(
                                'PRO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Label ─────────────────────────────────────────────────
            Expanded(
              flex: 28,
              child: Builder(
                builder: (ctx) => Container(
                  color: Theme.of(ctx).colorScheme.surface,
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        template.name,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(ctx).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        meta.tagline,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: Theme.of(ctx).colorScheme.onSurface.withAlpha(153),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
