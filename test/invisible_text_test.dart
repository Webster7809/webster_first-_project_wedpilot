import 'dart:math' as math;

import 'package:flutter/material.dart';
// RenderParagraph — the render object both Text and Icon paint through, and
// the only place the fully-resolved (inherited) colour can be read.
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wed_plan_pilot/core/theme/app_colors.dart';
import 'package:wed_plan_pilot/core/theme/app_theme.dart';
import 'package:wed_plan_pilot/features/shared/screens/settings_screen.dart';
import 'package:wed_plan_pilot/providers/settings_provider.dart';

/// Guards the bug this app keeps re-introducing: text or an icon painted in a
/// hardcoded light-theme ink (`AppColors.textPrimary`, `forestGreen`,
/// `primary`, …) on top of a background that *is* theme-aware — a card using
/// `colorScheme.surface`, a Scaffold, or an app bar with its own dark fill.
/// The result is near-black on near-black: content that is present, laid out
/// and hit-testable, but invisible. It has shipped at least four times (the
/// vendor filter sheet, the shortlist card, the settings section headers, and
/// most recently every app bar's back button and title).
///
/// A static scan for `color: AppColors.x` is useless here — 434 call sites in
/// 57 files, nearly all of them legitimate ink on a deliberately-always-white
/// sheet. So this measures the thing that actually matters instead: what got
/// painted, against what it was painted on.

/// Relative luminance per WCAG 2.1.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel((c.r * 255.0).round() / 255) +
      0.7152 * channel((c.g * 255.0).round() / 255) +
      0.0722 * channel((c.b * 255.0).round() / 255);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// Below this, content reads as "not there" rather than merely low-contrast.
/// Deliberately the 3:1 non-text floor and not AA 4.5:1 — this test is a
/// tripwire for invisibility, not a general contrast audit (design_system_test
/// already pins the token pairs at AA).
const _visibilityFloor = 3.0;

/// Walks up from [start] to the first ancestor that paints an opaque, solid
/// background, and returns its colour.
///
/// Returns null when the nearest painted ancestor is a gradient or an image —
/// a hero scrim over a photo, say. The background there is whatever pixels the
/// image happened to supply, which this can't know, so those subtrees are
/// skipped rather than guessed at and reported as false failures.
Color? _resolveBackground(Element start, ThemeData theme) {
  Color? background;
  bool undeterminable = false;

  start.visitAncestorElements((ancestor) {
    final widget = ancestor.widget;

    if (widget is Material) {
      final color = widget.color;
      if (color != null && color.a > 0) {
        background = color;
        return false;
      }
      // A Material with no colour of its own (type: transparency) keeps
      // looking upward.
      return true;
    }
    if (widget is ColoredBox) {
      if (widget.color.a > 0) {
        background = widget.color;
        return false;
      }
      return true;
    }
    if (widget is DecoratedBox) {
      final decoration = widget.decoration;
      if (decoration is BoxDecoration) {
        if (decoration.gradient != null || decoration.image != null) {
          undeterminable = true;
          return false;
        }
        final color = decoration.color;
        if (color != null && color.a > 0) {
          background = color;
          return false;
        }
      }
      return true;
    }
    return true;
  });

  if (undeterminable) return null;
  return background ?? theme.scaffoldBackgroundColor;
}

/// Every glyph in the pumped tree — [Text] and [Icon] alike, since Icon also
/// renders through a RenderParagraph — checked against whatever it sits on.
///
/// Reads the colour off the RenderParagraph rather than the widget's own
/// `style`, so inherited colour (DefaultTextStyle, IconTheme, an AppBar's
/// foregroundColor) is resolved exactly as it will be painted. That matters:
/// the app bar regression was invisible to any check that only looked at what
/// each screen passed in.
void expectNothingInvisible(
  WidgetTester tester, {
  required String context,
}) {
  final theme = Theme.of(tester.element(find.byType(MaterialApp)));
  final failures = <String>[];

  for (final element in tester.elementList(find.byType(Text))) {
    final renderObject = element.renderObject;
    if (renderObject is! RenderParagraph) continue;

    final foreground = renderObject.text.style?.color;
    if (foreground == null || foreground.a == 0) continue;

    final background = _resolveBackground(element, theme);
    if (background == null) continue; // gradient/image — unknowable, skipped

    final ratio = _contrast(foreground, background);
    if (ratio < _visibilityFloor) {
      final text = renderObject.text.toPlainText().trim();
      final label = text.isEmpty
          ? '<icon glyph>'
          : '"${text.length > 40 ? '${text.substring(0, 40)}…' : text}"';
      failures.add(
        '  $label — ${ratio.toStringAsFixed(2)}:1 '
        '(fg ${_hex(foreground)} on bg ${_hex(background)})',
      );
    }
  }

  expect(
    failures,
    isEmpty,
    reason: 'Invisible content in $context — these are painted but '
        'unreadable against their own background:\n${failures.join('\n')}',
  );
}

String _hex(Color c) =>
    '#${((c.a * 255).round() << 24 | (c.r * 255).round() << 16 | (c.g * 255).round() << 8 | (c.b * 255).round()).toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

/// Hive is never opened in a plain widget test, so
/// [SettingsNotifier.build]'s real box lookup would throw.
class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pump(WidgetTester tester, Widget home, ThemeData theme) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsProvider.overrideWith(_FakeSettingsNotifier.new)],
        child: MaterialApp(theme: theme, home: home),
      ),
    );
    await tester.pump();
  }

  // The exact shape that shipped broken: AppBar resolves icon and title colour
  // as `widget.iconTheme ?? appBarTheme.iconTheme ?? default(foregroundColor)`
  // (see AppBar.build), so an appBarTheme that hardcodes those two silently
  // outranks every screen's own `foregroundColor:` — leaving a near-black back
  // arrow and title on the forest fill that 21 screens use.
  group('an app bar that sets its own fill keeps its content legible', () {
    for (final entry in {'light': AppTheme.light, 'dark': AppTheme.dark}.entries) {
      testWidgets('forest app bar in ${entry.key} theme', (tester) async {
        await pump(
          tester,
          Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.forestGreen,
              foregroundColor: Colors.white,
              leading: const BackButton(),
              title: const Text('Settings'),
            ),
            body: const SizedBox.shrink(),
          ),
          entry.value,
        );

        expectNothingInvisible(tester, context: 'forest AppBar (${entry.key})');
      });
    }

    test('appBarTheme leaves icon and title colour to foregroundColor', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        expect(
          theme.appBarTheme.iconTheme,
          isNull,
          reason: 'A hardcoded appBarTheme.iconTheme outranks each screen\'s '
              'foregroundColor and repaints every forest app bar\'s back '
              'button in light-theme ink.',
        );
        expect(
          theme.appBarTheme.titleTextStyle?.color,
          isNull,
          reason: 'Same for the title: a colour here wins over foregroundColor '
              'and hides the title on any app bar with its own dark fill.',
        );
      }
    });
  });

  group('settings is readable in both themes', () {
    for (final entry in {'light': AppTheme.light, 'dark': AppTheme.dark}.entries) {
      testWidgets('SettingsScreen in ${entry.key} theme', (tester) async {
        tester.view.physicalSize = const Size(412, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await pump(tester, const SettingsScreen(), entry.value);

        expectNothingInvisible(tester, context: 'SettingsScreen (${entry.key})');
      });
    }
  });
}
