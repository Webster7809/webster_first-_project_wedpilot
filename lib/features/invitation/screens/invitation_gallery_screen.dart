import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/inherited/shell_scaffold.dart';
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
            expandedHeight: 120,
            pinned: true,
            backgroundColor: AppColors.secondary,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              tooltip: 'Open menu',
              onPressed: () =>
                  ShellScaffold.of(context)?.scaffoldKey.currentState?.openDrawer(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF880E4F), Color(0xFFC2185B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Wedding Invitations',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Choose a design that reflects your love story',
                          style: GoogleFonts.inter(
                            fontSize: 12,
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
                // ── My invitations ────────────────────────────────────
                if (myInvitations.isNotEmpty) ...[
                  _GallerySection(title: 'My Invitations', icon: Icons.bookmark_rounded),
                  const SizedBox(height: 10),
                  ...myInvitations.map((inv) => _MyInvitationCard(
                        invitation: inv,
                        onTap: () => context.push(
                          '/couple/invitations/editor?id=${inv.id}',
                        ),
                      )),
                  const SizedBox(height: 20),
                ],

                // ── Template gallery ──────────────────────────────────
                _GallerySection(
                  title: 'Choose Your Design',
                  icon: Icons.style_rounded,
                ),
                const SizedBox(height: 4),
                Text(
                  'Each theme comes with curated fonts and colour palettes.',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 14),

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
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.90,
                    ),
                    itemCount: templates.length,
                    itemBuilder: (_, i) {
                      final template = templates[i];
                      return _TemplateCard(
                        template: template,
                        onTap: () {
                          final newId = ref
                              .read(invitationsProvider.notifier)
                              .create(template.id, 'My Wedding Invitation');
                          context.push('/couple/invitations/editor?id=$newId');
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

// ── Gallery section header ──────────────────────────────────────────────────

class _GallerySection extends StatelessWidget {
  final String title;
  final IconData icon;
  const _GallerySection({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.secondary),
        const SizedBox(width: 7),
        Text(title, style: AppTextStyles.headlineSmall),
      ],
    );
  }
}

// ── My invitation card ──────────────────────────────────────────────────────
// Compact list-item style: ~68 px tall, shows title + status at a glance.

class _MyInvitationCard extends StatelessWidget {
  final dynamic invitation;
  final VoidCallback onTap;
  const _MyInvitationCard({required this.invitation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final published = (invitation.status.name as String) == 'published';
    final customData = invitation.customData as Map<String, dynamic>;
    final title = customData['coupleName'] as String? ?? invitation.title as String;
    final date = customData['date'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              // Mini gradient swatch
              Container(
                width: 42,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC2185B), Color(0xFF7B1FA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),

              // Title + meta in one column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
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
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded,
                  size: 18, color: AppColors.textSecondary),
            ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: published
            ? AppColors.info.withValues(alpha: 0.12)
            : AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            published ? Icons.share_outlined : Icons.edit_outlined,
            size: 10,
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

// ── Theme metadata ─────────────────────────────────────────────────────────

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
          _DecoElement('🌸', 48, Alignment.topRight, opacity: 0.35),
          _DecoElement('🌷', 32, Alignment.bottomLeft, opacity: 0.3),
        ],
      ),
    'modern' => _ThemeMeta(
        gradient: const [Color(0xFFF5F5F5), Color(0xFFE0E0E0)],
        textColor: const Color(0xFF212121),
        accentColor: const Color(0xFF424242),
        sampleFont: 'Montserrat',
        tagline: 'Clean lines & elegance',
        decor: [
          _DecoElement('◼', 38, Alignment.topRight, opacity: 0.12),
          _DecoElement('◻', 24, Alignment.bottomLeft, opacity: 0.1),
        ],
      ),
    'royal' => _ThemeMeta(
        gradient: const [Color(0xFF1A1A4E), Color(0xFF3F1DCB)],
        textColor: const Color(0xFFFFD700),
        accentColor: const Color(0xFFD4A854),
        sampleFont: 'Cormorant Garamond',
        tagline: 'Regal & grand',
        decor: [
          _DecoElement('👑', 44, Alignment.topRight, opacity: 0.45),
          _DecoElement('✦', 30, Alignment.bottomLeft, opacity: 0.35),
        ],
      ),
    'rustic' => _ThemeMeta(
        gradient: const [Color(0xFFF5ECD7), Color(0xFFDEB887)],
        textColor: const Color(0xFF4E342E),
        accentColor: const Color(0xFF795548),
        sampleFont: 'Abril Fatface',
        tagline: 'Earthy & botanical',
        decor: [
          _DecoElement('🌿', 46, Alignment.topRight, opacity: 0.4),
          _DecoElement('🍃', 30, Alignment.bottomLeft, opacity: 0.35),
        ],
      ),
    'boho' => _ThemeMeta(
        gradient: const [Color(0xFFFFF8EE), Color(0xFFE8D5B7)],
        textColor: const Color(0xFF5D4037),
        accentColor: const Color(0xFFBF8A68),
        sampleFont: 'Sacramento',
        tagline: 'Free-spirited & dreamy',
        decor: [
          _DecoElement('🪶', 44, Alignment.topRight, opacity: 0.45),
          _DecoElement('☽', 32, Alignment.bottomLeft, opacity: 0.3),
        ],
      ),
    'beach' => _ThemeMeta(
        gradient: const [Color(0xFFE0F7FF), Color(0xFF80DEEA)],
        textColor: const Color(0xFF01579B),
        accentColor: const Color(0xFF0288D1),
        sampleFont: 'Pacifico',
        tagline: 'Breezy ocean vibes',
        decor: [
          _DecoElement('🌊', 44, Alignment.topRight, opacity: 0.4),
          _DecoElement('🐚', 30, Alignment.bottomLeft, opacity: 0.35),
        ],
      ),
    'celestial' => _ThemeMeta(
        gradient: const [Color(0xFF0D0D2B), Color(0xFF1A0533)],
        textColor: const Color(0xFFE8C9FF),
        accentColor: const Color(0xFFAA88FF),
        sampleFont: 'Cinzel',
        tagline: 'Stars & mystical nights',
        decor: [
          _DecoElement('✨', 42, Alignment.topRight, opacity: 0.55),
          _DecoElement('🌙', 30, Alignment.bottomLeft, opacity: 0.5),
        ],
      ),
    'african' => _ThemeMeta(
        gradient: const [Color(0xFFFFF3CD), Color(0xFFFFCC02)],
        textColor: const Color(0xFF4A2000),
        accentColor: const Color(0xFFE65100),
        sampleFont: 'Lobster',
        tagline: 'Vibrant & cultural',
        decor: [
          _DecoElement('🌍', 44, Alignment.topRight, opacity: 0.45),
          _DecoElement('🥁', 30, Alignment.bottomLeft, opacity: 0.35),
        ],
      ),
    'islamic' => _ThemeMeta(
        gradient: const [Color(0xFFE8F5E9), Color(0xFFA5D6A7)],
        textColor: const Color(0xFF1B5E20),
        accentColor: const Color(0xFF2E7D32),
        sampleFont: 'Amiri',
        tagline: 'Graceful & sacred',
        decor: [
          _DecoElement('☪', 44, Alignment.topRight, opacity: 0.35),
          _DecoElement('🕌', 30, Alignment.bottomLeft, opacity: 0.3),
        ],
      ),
    'indian' => _ThemeMeta(
        gradient: const [Color(0xFFFFF8E1), Color(0xFFFFCC80)],
        textColor: const Color(0xFF7B1F00),
        accentColor: const Color(0xFFE64A19),
        sampleFont: 'Philosopher',
        tagline: 'Vibrant & festive',
        decor: [
          _DecoElement('🪔', 44, Alignment.topRight, opacity: 0.45),
          _DecoElement('🌺', 30, Alignment.bottomLeft, opacity: 0.4),
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

// ── Template card ───────────────────────────────────────────────────────────
// Visual-first thumbnail: gradient + decor fills ~65 % of the card, a
// gradient-scrim bottom panel shows the name and a compact CTA.

class _TemplateCard extends StatelessWidget {
  final dynamic template;
  final VoidCallback onTap;

  const _TemplateCard({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = _metaFor(template.theme as String);
    final isDark = meta.gradient.first.computeLuminance() < 0.15;
    // For dark-background themes, lighten the scrim slightly so text remains legible.
    final scrimEnd = isDark
        ? meta.gradient.last.withValues(alpha: 0.97)
        : meta.gradient.last.withValues(alpha: 0.92);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
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
              // ── Decorative theme elements (background)
              for (final d in meta.decor)
                Positioned.fill(
                  child: Align(
                    alignment: d.alignment,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Opacity(
                        opacity: d.opacity,
                        child: Text(d.symbol, style: TextStyle(fontSize: d.size)),
                      ),
                    ),
                  ),
                ),

              // ── Bottom scrim + info panel
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 18, 10, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, scrimEnd],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Accent rule
                      Container(
                        width: 22,
                        height: 2,
                        decoration: BoxDecoration(
                          color: meta.accentColor.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Template name
                      Text(
                        template.name as String,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: meta.textColor,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),

                      // Tagline
                      Text(
                        meta.tagline,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          color: meta.textColor.withValues(alpha: 0.65),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Select CTA
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          color: meta.accentColor,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Center(
                          child: Text(
                            'Select',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── PRO badge (top-left)
              if (template.isPremium as bool)
                Positioned(
                  top: 7,
                  left: 7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4A854),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, color: Colors.white, size: 8),
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
    );
  }
}
