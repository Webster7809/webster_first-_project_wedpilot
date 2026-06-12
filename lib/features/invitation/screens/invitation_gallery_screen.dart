import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: const Color(0xFFFAF7F4),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.secondary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFC2185B), Color(0xFF880E4F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Wedding Invitations',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose a design that reflects your love story',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (myInvitations.isNotEmpty) ...[
                  _GallerySection(title: 'My Invitations', icon: Icons.bookmark_rounded),
                  const SizedBox(height: 12),
                  ...myInvitations.map((inv) => _MyInvitationTile(
                        invitation: inv,
                        onTap: () => context.push('/couple/invitations/editor?id=${inv.id}'),
                      )),
                  const SizedBox(height: 24),
                ],
                _GallerySection(title: 'Choose Your Template', icon: Icons.style_rounded),
                const SizedBox(height: 6),
                Text(
                  'Each design comes with curated fonts and colour palettes.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 16),
                templatesAsync.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (e, _) => Center(child: Text('Error: $e')),
                  data: (templates) => GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: templates.length,
                    itemBuilder: (_, i) {
                      final template = templates[i];
                      return _TemplateCard(
                        template: template,
                        onTap: () {
                          ref
                              .read(invitationsProvider.notifier)
                              .create(template.id, 'My Wedding Invitation');
                          context.push('/couple/invitations/editor');
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _GallerySection extends StatelessWidget {
  final String title;
  final IconData icon;
  const _GallerySection({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.secondary),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.headlineSmall),
      ],
    );
  }
}

class _MyInvitationTile extends StatelessWidget {
  final dynamic invitation;
  final VoidCallback onTap;
  const _MyInvitationTile({required this.invitation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final published = (invitation.status.name as String) == 'published';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC2185B), Color(0xFF7B1FA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.mail_rounded, color: Colors.white, size: 22),
        ),
        title: Text(invitation.title as String, style: AppTextStyles.titleMedium),
        subtitle: Row(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: published
                    ? AppColors.success.withValues(alpha: 0.12)
                    : AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                published ? 'Published' : 'Draft',
                style: AppTextStyles.caption.copyWith(
                  color: published ? AppColors.success : AppColors.warning,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }
}

// ─── Theme metadata ────────────────────────────────────────────────────────

class _ThemeMeta {
  final List<Color> gradient;
  final Color textColor;
  final Color accentColor;
  final String sampleFont;
  final String tagline;
  final List<_DecoElement> decor;

  const _ThemeMeta({
    required this.gradient,
    required this.textColor,
    required this.accentColor,
    required this.sampleFont,
    required this.tagline,
    this.decor = const [],
  });
}

class _DecoElement {
  final String symbol;
  final double size;
  final Alignment alignment;
  final double opacity;
  const _DecoElement(this.symbol, this.size, this.alignment, {this.opacity = 0.25});
}

_ThemeMeta _metaFor(String theme) {
  return switch (theme) {
    'romantic' => _ThemeMeta(
        gradient: const [Color(0xFFFFF0F5), Color(0xFFFFC1D9)],
        textColor: const Color(0xFF880E4F),
        accentColor: const Color(0xFFC2185B),
        sampleFont: 'Great Vibes',
        tagline: 'Soft florals & romance',
        decor: [
          _DecoElement('🌸', 56, Alignment.topRight, opacity: 0.35),
          _DecoElement('🌷', 38, Alignment.bottomLeft, opacity: 0.3),
        ],
      ),
    'modern' => _ThemeMeta(
        gradient: const [Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
        textColor: const Color(0xFF212121),
        accentColor: const Color(0xFF424242),
        sampleFont: 'Montserrat',
        tagline: 'Clean lines & elegance',
        decor: [
          _DecoElement('◼', 44, Alignment.topRight, opacity: 0.12),
          _DecoElement('◻', 28, Alignment.bottomLeft, opacity: 0.1),
        ],
      ),
    'royal' => _ThemeMeta(
        gradient: const [Color(0xFF1A1A4E), Color(0xFF3F1DCB)],
        textColor: const Color(0xFFFFD700),
        accentColor: const Color(0xFFD4A854),
        sampleFont: 'Cormorant Garamond',
        tagline: 'Regal & grand',
        decor: [
          _DecoElement('👑', 52, Alignment.topRight, opacity: 0.45),
          _DecoElement('✦', 36, Alignment.bottomLeft, opacity: 0.35),
        ],
      ),
    'rustic' => _ThemeMeta(
        gradient: const [Color(0xFFF5ECD7), Color(0xFFDEB887)],
        textColor: const Color(0xFF4E342E),
        accentColor: const Color(0xFF795548),
        sampleFont: 'Abril Fatface',
        tagline: 'Earthy & botanical',
        decor: [
          _DecoElement('🌿', 54, Alignment.topRight, opacity: 0.4),
          _DecoElement('🍃', 36, Alignment.bottomLeft, opacity: 0.35),
        ],
      ),
    'boho' => _ThemeMeta(
        gradient: const [Color(0xFFFFF8EE), Color(0xFFE8D5B7)],
        textColor: const Color(0xFF5D4037),
        accentColor: const Color(0xFFBF8A68),
        sampleFont: 'Sacramento',
        tagline: 'Free-spirited & dreamy',
        decor: [
          _DecoElement('🪶', 52, Alignment.topRight, opacity: 0.45),
          _DecoElement('☽', 38, Alignment.bottomLeft, opacity: 0.3),
        ],
      ),
    'beach' => _ThemeMeta(
        gradient: const [Color(0xFFE0F7FF), Color(0xFF80DEEA)],
        textColor: const Color(0xFF01579B),
        accentColor: const Color(0xFF0288D1),
        sampleFont: 'Pacifico',
        tagline: 'Breezy ocean vibes',
        decor: [
          _DecoElement('🌊', 52, Alignment.topRight, opacity: 0.4),
          _DecoElement('🐚', 38, Alignment.bottomLeft, opacity: 0.35),
        ],
      ),
    'celestial' => _ThemeMeta(
        gradient: const [Color(0xFF0D0D2B), Color(0xFF1A0533)],
        textColor: const Color(0xFFE8C9FF),
        accentColor: const Color(0xFFAA88FF),
        sampleFont: 'Cinzel',
        tagline: 'Stars & mystical nights',
        decor: [
          _DecoElement('✨', 50, Alignment.topRight, opacity: 0.55),
          _DecoElement('🌙', 38, Alignment.bottomLeft, opacity: 0.5),
        ],
      ),
    'african' => _ThemeMeta(
        gradient: const [Color(0xFFFFF3CD), Color(0xFFFFCC02)],
        textColor: const Color(0xFF4A2000),
        accentColor: const Color(0xFFE65100),
        sampleFont: 'Lobster',
        tagline: 'Vibrant & cultural',
        decor: [
          _DecoElement('🌍', 52, Alignment.topRight, opacity: 0.45),
          _DecoElement('🥁', 36, Alignment.bottomLeft, opacity: 0.35),
        ],
      ),
    'islamic' => _ThemeMeta(
        gradient: const [Color(0xFFE8F5E9), Color(0xFFA5D6A7)],
        textColor: const Color(0xFF1B5E20),
        accentColor: const Color(0xFF2E7D32),
        sampleFont: 'Amiri',
        tagline: 'Graceful & sacred',
        decor: [
          _DecoElement('☪', 52, Alignment.topRight, opacity: 0.35),
          _DecoElement('🕌', 38, Alignment.bottomLeft, opacity: 0.3),
        ],
      ),
    'indian' => _ThemeMeta(
        gradient: const [Color(0xFFFFF8E1), Color(0xFFFFCC80)],
        textColor: const Color(0xFF7B1F00),
        accentColor: const Color(0xFFE64A19),
        sampleFont: 'Philosopher',
        tagline: 'Vibrant & festive',
        decor: [
          _DecoElement('🪔', 52, Alignment.topRight, opacity: 0.45),
          _DecoElement('🌺', 38, Alignment.bottomLeft, opacity: 0.4),
        ],
      ),
    _ => _ThemeMeta(
        gradient: const [Color(0xFFFFF0F5), Color(0xFFFFC1D9)],
        textColor: const Color(0xFF880E4F),
        accentColor: const Color(0xFFC2185B),
        sampleFont: 'Great Vibes',
        tagline: 'Beautiful & elegant',
      ),
  };
}

// ─── Template Card ──────────────────────────────────────────────────────────

class _TemplateCard extends StatelessWidget {
  final dynamic template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = _metaFor(template.theme as String);
    final isDark = meta.gradient.first.computeLuminance() < 0.15;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: meta.gradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: meta.gradient.last.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative background elements
            for (final d in meta.decor)
              Positioned.fill(
                child: Align(
                  alignment: d.alignment,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      d.symbol,
                      style: TextStyle(fontSize: d.size),
                    ),
                  ),
                ),
              ),

            // PRO badge
            if (template.isPremium as bool)
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.goldPremium,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.white, size: 10),
                      const SizedBox(width: 3),
                      const Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Card content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),

                    // Divider line
                    Container(
                      width: 32,
                      height: 2,
                      decoration: BoxDecoration(
                        color: meta.accentColor.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Template name
                    Text(
                      template.name as String,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: meta.textColor,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Tagline
                    Text(
                      meta.tagline,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: meta.textColor.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Font preview
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : meta.accentColor).withValues(alpha: isDark ? 0.08 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: meta.accentColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aa — ${meta.sampleFont}',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              color: meta.textColor.withValues(alpha: 0.55),
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sarah & James',
                            style: _fontPreviewStyle(meta.sampleFont).copyWith(
                              fontSize: 13,
                              color: meta.accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // CTA
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: meta.accentColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Use This Design',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _fontPreviewStyle(String fontName) {
    return switch (fontName) {
      'Great Vibes' => GoogleFonts.greatVibes(),
      'Montserrat' => GoogleFonts.montserrat(fontWeight: FontWeight.w600),
      'Cormorant Garamond' => GoogleFonts.cormorantGaramond(fontWeight: FontWeight.w600),
      'Abril Fatface' => GoogleFonts.abrilFatface(),
      'Sacramento' => GoogleFonts.sacramento(),
      'Pacifico' => GoogleFonts.pacifico(),
      'Cinzel' => GoogleFonts.cinzel(fontWeight: FontWeight.w600),
      'Lobster' => GoogleFonts.lobster(),
      'Amiri' => GoogleFonts.amiri(fontWeight: FontWeight.w700),
      'Philosopher' => GoogleFonts.philosopher(fontWeight: FontWeight.w700),
      _ => GoogleFonts.playfairDisplay(),
    };
  }
}
