import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:wed_plan_pilot/app.dart';
import 'package:wed_plan_pilot/providers/session_restore_provider.dart';
import 'package:wed_plan_pilot/providers/settings_provider.dart';

/// Skips [SettingsNotifier.build]'s real `Hive.box('app_settings')` lookup,
/// which throws in a plain widget test since no Hive box has been opened —
/// returns plain defaults instead.
class _FakeSettingsNotifier extends SettingsNotifier {
  @override
  AppSettings build() => const AppSettings();
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // sessionRestoreProvider normally reads flutter_secure_storage via a
          // platform channel, which never resolves in a plain widget test (no
          // plugin binding registered) — override it to resolve immediately
          // as "no stored session", same as a fresh install.
          sessionRestoreProvider.overrideWith((ref) async {}),
          settingsProvider.overrideWith(_FakeSettingsNotifier.new),
        ],
        child: const WedpilotApp(),
      ),
    );
    // Avoid pumpAndSettle: swapping from the loading placeholder to the real
    // MaterialApp.router triggers a brief implicit text-style transition
    // (Flutter's default theme label style animating to the app's custom
    // one) that never fully "settles" the way pumpAndSettle demands.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
