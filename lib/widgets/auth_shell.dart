import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_shadows.dart';
import '../core/theme/app_text_styles.dart';

/// Below this width the photograph and the form can't both breathe side by
/// side, so the hero stacks above the form instead (phone, tablet, small
/// windows).
const double _splitMinWidth = 1000;

/// A window can clear [_splitMinWidth] and still be too short for a
/// full-height photo pane — a laptop with devtools docked, a half-height
/// browser. The split pane can't scroll, so fall back to the stacked layout
/// rather than squeeze it.
const double _splitMinHeight = 620;

/// Two fields only share a line when each half still clears a comfortable
/// field width.
const double _sideBySideMinWidth = 420;

/// Corner radius of the form sheet, and the distance it overlaps the hero by.
const double _sheetRadius = 28;

/// Keeps hero copy readable over the brightest part of the photograph without
/// having to darken the photograph itself.
const List<Shadow> _heroShadow = [
  Shadow(color: Color.fromARGB(115, 0, 0, 0), blurRadius: 14, offset: Offset(0, 2)),
];

/// One selling point in the photo pane of the split layout.
class AuthBenefit {
  final IconData icon;
  final String title;
  final String body;

  const AuthBenefit(this.icon, this.title, this.body);
}

/// The frame every signed-out screen sits in: a photograph, a form sheet, and
/// a cross-link to the other screen.
///
/// Two layouts come out of one `LayoutBuilder`:
///
/// * **Split** (laptop, desktop) — the photograph takes a full-height pane of
///   its own so it reads as a portrait rather than a letterboxed strip, and
///   the form sits beside it at a comfortable measure instead of stretched
///   across the window or marooned in the middle of it. [benefits] fill what
///   would otherwise be a large empty rectangle.
/// * **Stacked** (phone, tablet, short or narrow windows) — an edge-to-edge
///   photo hero with the form sheet lifted over its bottom edge.
///
/// [formBuilder] is handed a `sideBySide` flag: true when the form is wide
/// enough to put two fields on one line.
class AuthShell extends StatelessWidget {
  final String imageUrl;
  final String eyebrow;
  final String headline;

  /// Shown under the headline on the split layout only, and only when
  /// [benefits] is empty. The stacked hero stays at eyebrow + headline so the
  /// photograph keeps roughly half the frame to itself.
  final String? supportLine;

  /// Shown under the headline on the split layout only.
  final List<AuthBenefit> benefits;

  final String crossLinkPrompt;
  final String crossLinkAction;
  final String crossLinkRoute;

  /// Overrides the plain `go(crossLinkRoute)` when the cross-link has to do
  /// something first. The verify screen needs it: its visitor is already
  /// signed in, so a bare link to `/login` is bounced straight back by the
  /// router and the affordance does nothing — it has to sign out first.
  final VoidCallback? crossLinkOnTap;

  /// Back affordance for routes that were pushed rather than replaced
  /// (`/forgot-password` is pushed from login). Drawn over the photograph
  /// rather than in an `AppBar`, which would put a cream bar above the hero
  /// and break the edge-to-edge image. Leave null on routes with nothing to
  /// go back to — a deep link, or a screen reached with `go`.
  final VoidCallback? onBack;

  final Widget Function(BuildContext context, bool sideBySide) formBuilder;

  const AuthShell({
    super.key,
    required this.imageUrl,
    required this.eyebrow,
    required this.headline,
    required this.crossLinkPrompt,
    required this.crossLinkAction,
    required this.crossLinkRoute,
    required this.formBuilder,
    this.supportLine,
    this.benefits = const [],
    this.onBack,
    this.crossLinkOnTap,
  });

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    // Both layouts size themselves off the text scale rather than capping it:
    // the hero grows with the type instead of clipping it, and a large scale
    // sends a borderline window to the stacked (scrollable) layout.
    final textScale =
        (MediaQuery.textScalerOf(context).scale(16) / 16).clamp(1.0, 1.6);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.forestGreen,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final fitsSplit = constraints.maxWidth >= _splitMinWidth &&
                constraints.maxHeight >= _splitMinHeight * textScale;

            return fitsSplit
                ? _split(context, topInset: insets.top)
                : _stacked(
                    context,
                    width: constraints.maxWidth,
                    topInset: insets.top,
                    bottomInset: insets.bottom,
                    textScale: textScale,
                  );
          },
        ),
      ),
    );
  }

  Widget _split(BuildContext context, {required double topInset}) {
    return Row(
      // Stretch, not the default centre: it is what gives the photo pane a
      // tight height to fill, and what lets its copy sit on the bottom edge.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _HeroPanel(
            imageUrl: imageUrl,
            eyebrow: eyebrow,
            headline: headline,
            supportLine: benefits.isEmpty ? supportLine : null,
            benefits: benefits,
            padding: const EdgeInsets.fromLTRB(52, 44, 52, 52),
            topInset: topInset,
            headlineStyle: AppTextStyles.displayLarge,
            onBack: onBack,
          ),
        ),
        Expanded(
          child: ColoredBox(
            color: AppColors.cream,
            child: SafeArea(
              left: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 26, 0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _CrossLink(
                        prompt: crossLinkPrompt,
                        action: crossLinkAction,
                        route: crossLinkRoute,
                        onTap: crossLinkOnTap,
                        onDark: false,
                      ),
                    ),
                  ),
                  // Centre a form that fits, scroll one that doesn't. Login
                  // is two fields and would otherwise sit in the top third of
                  // the pane with a third of a screen of empty cream below it;
                  // register is long enough that this just scrolls.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, pane) {
                        const padding = EdgeInsets.fromLTRB(32, 16, 32, 48);
                        return SingleChildScrollView(
                          padding: padding,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: pane.maxHeight - padding.vertical,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 460),
                                child: formBuilder(context, true),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stacked(
    BuildContext context, {
    required double width,
    required double topInset,
    required double bottomInset,
    required double textScale,
  }) {
    final isTablet = width >= 600;
    final contentWidth = isTablet ? 560.0 : width;

    // A floor, not a fixed height. Whatever the copy needs it gets; the floor
    // only guarantees enough clear photograph above it — roughly a square on a
    // phone, which leaves the couple about half the frame to themselves.
    // Scaled by the text scale so that clear band survives a large type
    // setting too.
    final heroMinHeight =
        contentWidth.clamp(340.0, 450.0) * textScale + topInset;

    final cardPadding = isTablet
        ? const EdgeInsets.fromLTRB(32, 30, 32, 34)
        : const EdgeInsets.fromLTRB(20, 26, 20, 30);

    final hero = ConstrainedBox(
      constraints: BoxConstraints(minHeight: heroMinHeight),
      child: _HeroPanel(
        imageUrl: imageUrl,
        eyebrow: eyebrow,
        headline: headline,
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
        topInset: topInset,
        headlineStyle: AppTextStyles.displayMedium,
        onBack: onBack,
      ),
    );

    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isTablet ? contentWidth : double.infinity,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isTablet) ...[
                const SizedBox(height: 28),
                ClipRRect(
                  borderRadius: AppRadius.top(_sheetRadius),
                  child: hero,
                ),
              ] else
                hero,

              // Painted over the bottom of the photo rather than butted
              // against it, so the sheet's rounded corners reveal the
              // photograph instead of two green wedges.
              Transform.translate(
                offset: const Offset(0, -_sheetRadius),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: const BorderRadius.all(
                      Radius.circular(_sheetRadius),
                    ),
                    boxShadow: AppShadows.xl,
                  ),
                  padding: cardPadding,
                  child: formBuilder(
                    context,
                    contentWidth - cardPadding.horizontal >=
                        _sideBySideMinWidth,
                  ),
                ),
              ),

              Center(
                child: _CrossLink(
                  prompt: crossLinkPrompt,
                  action: crossLinkAction,
                  route: crossLinkRoute,
                  onTap: crossLinkOnTap,
                  onDark: true,
                ),
              ),
              SizedBox(height: 24 + bottomInset),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero ──────────────────────────────────────────────────────────────────────

/// The photograph, with the brand lockup and headline set as one block on its
/// bottom edge.
///
/// Two things keep the couple looking like a photograph rather than a green
/// silhouette. The copy is bottom-anchored, so the upper half of the frame —
/// where the faces land — carries nothing. And the scrim is not a flat wash:
/// it runs a thin dark cap (enough for status-bar icons) → near-clear → dark
/// under the copy. A flat forest overlay at 84% is what washed these photos
/// out before.
///
/// The panel takes its height from the copy and grows past any floor it is
/// given, so no type scale can push the block off the bottom of the frame.
class _HeroPanel extends StatelessWidget {
  final String imageUrl;
  final String eyebrow;
  final String headline;
  final String? supportLine;
  final List<AuthBenefit> benefits;

  /// Padding around the copy. [topInset] is added to the top so the block
  /// clears the status bar if the copy ever fills the whole frame.
  final EdgeInsets padding;
  final double topInset;
  final TextStyle headlineStyle;
  final VoidCallback? onBack;

  const _HeroPanel({
    required this.imageUrl,
    required this.eyebrow,
    required this.headline,
    required this.padding,
    required this.topInset,
    required this.headlineStyle,
    this.supportLine,
    this.benefits = const [],
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Positioned.fill(
          // Decode at the size actually painted, not the 1600px the URL asks
          // for. Without this the full image is decoded into memory on every
          // auth screen — roughly 15MB of RGBA for a 1600x2400 portrait on a
          // phone that only ever shows it 390pt wide.
          child: LayoutBuilder(
            builder: (context, panel) {
              final decodeWidth =
                  (panel.maxWidth * MediaQuery.devicePixelRatioOf(context))
                      .round()
                      .clamp(400, 1600);
              return CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: decodeWidth,
                // The sources are portraits. Anchoring the crop to the top
                // keeps both faces inside it at every pane shape, rather than
                // framing chins the way a centred crop did on the old
                // letterbox hero.
                alignment: Alignment.topCenter,
                fadeInDuration: const Duration(milliseconds: 350),
                placeholder: (_, _) =>
                    const ColoredBox(color: AppColors.forestDeep),
                errorWidget: (_, _, _) =>
                    const ColoredBox(color: AppColors.forestDeep),
              );
            },
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.18, 0.48, 1.0],
                colors: [
                  AppColors.forestDeep.withAlpha(118),
                  AppColors.forestDeep.withAlpha(24),
                  AppColors.forestDeep.withAlpha(92),
                  AppColors.forestDeep.withAlpha(243),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: padding.copyWith(top: padding.top + topInset),
          child: ConstrainedBox(
            // Caps the measure so a wide pane doesn't stretch the headline
            // into one thin line across the window.
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _BrandLockup(),
                SizedBox(height: benefits.isEmpty ? 26 : 32),
                Text(
                  eyebrow,
                  // Gold, not forest: this eyebrow sits on the forest-tinted
                  // photo scrim. Forest on forest is invisible.
                  style: AppTextStyles.overline.copyWith(
                    color: AppColors.gold,
                    letterSpacing: 1.6,
                    shadows: _heroShadow,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  headline,
                  style: headlineStyle.copyWith(
                    color: Colors.white,
                    shadows: _heroShadow,
                  ),
                ),
                if (supportLine != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    supportLine!,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: const Color.fromARGB(214, 255, 255, 255),
                      height: 1.5,
                      shadows: _heroShadow,
                    ),
                  ),
                ],
                if (benefits.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  for (final benefit in benefits) _BenefitRow(benefit: benefit),
                ],
              ],
            ),
          ),
        ),
        if (onBack != null)
          Positioned(
            top: topInset + 10,
            left: 10,
            child: _HeroBackButton(onTap: onBack!),
          ),
      ],
    );
  }
}

/// Back arrow over the photograph. Glassy rather than solid so it reads as an
/// overlay on the image instead of a floating chip, with a hairline and a
/// shadow to keep the white arrow off a bright frame.
class _HeroBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _HeroBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color.fromARGB(46, 255, 255, 255),
      shape: CircleBorder(
        side: BorderSide(color: Colors.white.withAlpha(72)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Tooltip(
          message: 'Back',
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.arrow_back,
              size: 21,
              color: Colors.white,
              shadows: _heroShadow,
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(AppRadius.r14),
            boxShadow: AppShadows.md,
          ),
          // Ink on gold, never white — white on gold is 2.42:1.
          child: const Icon(
            Icons.favorite,
            color: AppColors.textOnSecondary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            'WedPilot',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.displaySmall.copyWith(
              color: Colors.white,
              shadows: _heroShadow,
            ),
          ),
        ),
      ],
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final AuthBenefit benefit;

  const _BenefitRow({required this.benefit});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.gold.withAlpha(46),
              borderRadius: BorderRadius.circular(AppRadius.r10),
              border: Border.all(color: AppColors.gold.withAlpha(95)),
            ),
            child: Icon(benefit.icon, size: 17, color: AppColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    shadows: _heroShadow,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  benefit.body,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: const Color.fromARGB(206, 255, 255, 255),
                    height: 1.4,
                    shadows: _heroShadow,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status ────────────────────────────────────────────────────────────────────

/// Which of the three things happened. Drives the badge colour only — the
/// tones are the semantic ones, already measured against cream by
/// `test/design_system_test.dart`.
enum AuthStatusTone {
  /// The link was sent, the password was changed.
  success,

  /// The reset link is missing or malformed.
  error,

  /// Waiting on the user to do something in their inbox.
  pending,
}

/// The "check your email" / "password updated" / "invalid link" moment, shown
/// in the form sheet in place of the form.
///
/// Not [WedEmptyState]: that one is a full-height `Center` sized for an empty
/// list, with a 64px gold glyph and a `subheading` title. This sits inside the
/// auth sheet, keeps the serif title the other auth screens use, and takes a
/// stack of actions rather than a single CTA.
class AuthStatus extends StatelessWidget {
  final IconData icon;
  final AuthStatusTone tone;
  final String title;
  final String message;

  /// Buttons under the message, already spaced.
  final List<Widget> actions;

  /// Swaps the glyph for a spinner while the outcome is still unknown — the
  /// badge, title and message stay put, so resolving doesn't jump the layout.
  final bool busy;

  const AuthStatus({
    super.key,
    required this.icon,
    required this.tone,
    required this.title,
    required this.message,
    this.actions = const [],
    this.busy = false,
  });

  Color get _tone => switch (tone) {
    AuthStatusTone.success => AppColors.success,
    AuthStatusTone.error => AppColors.error,
    AuthStatusTone.pending => AppColors.forestGreen,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          child: Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _tone.withAlpha(28),
              borderRadius: BorderRadius.circular(AppRadius.r20),
              border: Border.all(color: _tone.withAlpha(64)),
            ),
            child: busy
                ? SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: _tone,
                    ),
                  )
                : Icon(icon, size: 32, color: _tone),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTextStyles.displaySmall.copyWith(
            color: AppColors.forestGreen,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.55,
          ),
        ),
        for (final action in actions) ...[
          const SizedBox(height: 14),
          action,
        ],
      ],
    );
  }
}

// ── Cross-link ────────────────────────────────────────────────────────────────

/// "Already planning with us? Log in" / "New to WedPilot? Create an account".
///
/// On the stacked layout this sits on the forest scaffold below the sheet, so
/// the accent has to be gold — forest on forest is invisible, and
/// `test/login_screen_test.dart` pins that. On the split layout it sits on
/// cream in the form pane, where forest is the accessible choice (12.08:1) and
/// gold would not be.
class _CrossLink extends StatelessWidget {
  final String prompt;
  final String action;
  final String route;
  final bool onDark;

  /// Replaces the plain navigation to [route] when set.
  final VoidCallback? onTap;

  const _CrossLink({
    required this.prompt,
    required this.action,
    required this.route,
    required this.onDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r8),
        onTap: onTap ?? () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.bodyMedium.copyWith(
                color: onDark
                    ? const Color.fromARGB(203, 255, 255, 255)
                    : AppColors.textSecondary,
              ),
              children: [
                TextSpan(text: '$prompt  '),
                TextSpan(
                  text: action,
                  style: TextStyle(
                    color: onDark ? AppColors.gold : AppColors.forestGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
