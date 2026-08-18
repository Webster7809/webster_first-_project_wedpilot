import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wed_plan_pilot/core/theme/app_theme.dart';
import 'package:wed_plan_pilot/widgets/auth_shell.dart';
import 'package:wed_plan_pilot/widgets/dash_progress_bar.dart';
import 'package:wed_plan_pilot/widgets/section_header.dart';
import 'package:wed_plan_pilot/widgets/wed_button.dart';
import 'package:wed_plan_pilot/widgets/wed_card.dart';
import 'package:wed_plan_pilot/widgets/wed_chip.dart';
import 'package:wed_plan_pilot/widgets/wed_empty_state.dart';
import 'package:wed_plan_pilot/widgets/wed_score_badge.dart';
import 'package:wed_plan_pilot/widgets/wed_avatar.dart';
import 'package:wed_plan_pilot/widgets/wed_error_state.dart';
import 'package:wed_plan_pilot/widgets/wed_skeleton.dart';
import 'package:wed_plan_pilot/widgets/wed_text_field.dart';
import 'package:wed_plan_pilot/widgets/wizard_widgets.dart';

/// Swapping the app off Roboto onto Inter and Playfair Display changes glyph
/// metrics, so text that used to fit can start overflowing. These render the
/// shared components at the narrowest widths WedPilot realistically sees, with
/// deliberately long Zambian-market strings, and fail on any overflow.
///
/// 320 is a small Android phone, 360 the most common, 412 a large one.
const _widths = <double>[320, 360, 412];

/// Also exercise the largest text scale a user can pick, since AppSettings
/// feeds a textScaler multiplier into the whole tree.
const _scales = <double>[1.0, 1.3];

Future<void> _pumpAtEveryWidth(
  WidgetTester tester,
  String label,
  Widget child,
) async {
  for (final width in _widths) {
    for (final scale in _scales) {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: '$label overflowed at ${width}px, textScale $scale',
      );
    }
  }
}

void main() {
  testWidgets('every WedButton variant fits', (tester) async {
    for (final variant in WedButtonVariant.values) {
      await _pumpAtEveryWidth(
        tester,
        'WedButton.${variant.name}',
        WedButton(
          label: 'Send an inquiry to this vendor',
          variant: variant,
          onPressed: () {},
        ),
      );
    }
  });

  testWidgets('section header shrinks its title rather than overflowing',
      (tester) async {
    await _pumpAtEveryWidth(
      tester,
      'WedSectionHeader',
      const WedSectionHeader(
        title: 'Vendors matched to your wedding in Lusaka',
        actionLabel: 'See all',
      ),
    );
  });

  testWidgets('card with a long vendor name fits', (tester) async {
    await _pumpAtEveryWidth(
      tester,
      'WedCard',
      const WedCard(
        child: Text('Chembe Gardens Conference & Events Centre, Lusaka'),
      ),
    );
  });

  testWidgets('empty state fits', (tester) async {
    await _pumpAtEveryWidth(
      tester,
      'WedEmptyState',
      const WedEmptyState(
        icon: Icons.favorite_outlined,
        title: 'Nothing saved yet',
        message:
            'Vendors you save while browsing will collect here so you can '
            'compare them side by side later.',
        ctaLabel: 'Browse vendors',
      ),
    );
  });

  testWidgets('a row of filter chips wraps instead of overflowing',
      (tester) async {
    await _pumpAtEveryWidth(
      tester,
      'WedChip row',
      const Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          WedChip(label: 'All'),
          WedChip(label: 'Under K30,000', isSelected: true),
          WedChip(label: 'Verified'),
          WedChip(label: 'Fits my guests'),
        ],
      ),
    );
  });

  testWidgets('score badge fits', (tester) async {
    await _pumpAtEveryWidth(
      tester,
      'WedScoreBadge',
      const WedScoreBadge(score: '4.8'),
    );
  });

  // Not run through _pumpAtEveryWidth: WedListSkeleton is a ListView and needs
  // a bounded height, which is exactly the constraint that would break if one
  // were ever dropped into an unbounded Column.
  testWidgets('list skeleton renders in a Scaffold body', (tester) async {
    for (final skeleton in const [
      WedListSkeleton(rows: 6),
      WedListSkeleton(rows: 6, hasLeading: false),
      WedListSkeleton(rows: 4, asCards: true, cardHeight: 140),
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(body: skeleton),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    }
  });

  // ── Widgets that reach every screen ─────────────────────────────────────
  //
  // These are shared, so an overflow in one of them is an overflow in dozens
  // of screens at once — cheaper to pin here than to fixture 44 screens.

  testWidgets('text field fits with a long label, hint and error',
      (tester) async {
    await _pumpAtEveryWidth(
      tester,
      'WedTextField',
      const WedTextField(
        label: 'Which town or city is the wedding in?',
        hint: 'Start typing to search for your venue location',
        errorText: 'We could not find any vendors serving that location',
        prefixIcon: Icons.location_on_outlined,
      ),
    );
  });

  testWidgets('error state fits', (tester) async {
    await _pumpAtEveryWidth(
      tester,
      'WedErrorState',
      WedErrorState(
        title: "Couldn't load your dashboard",
        message:
            'We could not reach WedPilot just now. Check your connection and '
            'try again in a moment.',
        retryLabel: 'Try again',
        onRetry: () {},
      ),
    );
  });

  testWidgets('avatar fits at every size', (tester) async {
    for (final size in WedAvatarSize.values) {
      await _pumpAtEveryWidth(
        tester,
        'WedAvatar.${size.name}',
        WedAvatar(name: 'Chembe Gardens Conference Centre', size: size),
      );
    }
  });

  // Pumped by hand rather than through _pumpAtEveryWidth: RingFlourish
  // animates continuously, so pumpAndSettle never returns for this one.
  testWidgets('wizard header fits', (tester) async {
    for (final width in _widths) {
      for (final scale in _scales) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: MaterialApp(
              theme: AppTheme.light,
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: WizardHeader(
                    step: 2,
                    totalSteps: 4,
                    stepLabel: 'STYLE & PREFERENCES',
                    stepTitle: "What's your\nwedding style?",
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(
          tester.takeException(),
          isNull,
          reason: 'WizardHeader overflowed at ${width}px, textScale $scale',
        );
      }
    }
  });

  testWidgets('progress bar fits at every step count', (tester) async {
    for (final total in const [3, 4, 8, 12]) {
      await _pumpAtEveryWidth(
        tester,
        'DashProgressBar($total)',
        DashProgressBar(total: total, current: total ~/ 2),
      );
    }
  });

  testWidgets('auth status fits with long copy and two actions',
      (tester) async {
    for (final tone in AuthStatusTone.values) {
      await _pumpAtEveryWidth(
        tester,
        'AuthStatus.${tone.name}',
        AuthStatus(
          icon: Icons.mark_email_unread_outlined,
          tone: tone,
          title: 'Check your inbox',
          message:
              'We sent a verification link to averyveryverylongaddress@'
              'example-domain.co.zm. Open it to activate your account, then '
              'come back here.',
          actions: [
            WedButton(label: "I've verified — continue", onPressed: () {}),
            WedButton(
              label: 'Resend in 60s',
              variant: WedButtonVariant.secondary,
              onPressed: () {},
            ),
          ],
        ),
      );
    }
  });
}
