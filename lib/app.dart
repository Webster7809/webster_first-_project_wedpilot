import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/session_restore_provider.dart';
import 'providers/settings_provider.dart';

// Flutter's default ScrollBehavior excludes mouse from drag-to-scroll
// devices (it's normally reserved for text/content selection on desktop),
// so on web/desktop a click-and-drag on a scrollable area does nothing —
// only the mouse wheel or trackpad scrolls. This app has no text-selection
// use case that a mouse-drag scroll would conflict with, so enable it
// everywhere rather than leaving every scroll view feeling "stuck".
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        ...super.dragDevices,
        PointerDeviceKind.mouse,
      };
}

class WedpilotApp extends ConsumerWidget {
  const WedpilotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionRestore = ref.watch(sessionRestoreProvider);

    // A public invite link needs no auth state to render — it's the same
    // page for a logged-in couple previewing their own invite or a signed-out
    // guest. Gating it behind this loading screen was actively breaking it:
    // GoRouter only reads the browser's real initial path (e.g. /i/token)
    // when MaterialApp.router first mounts. Showing this plain, router-less
    // MaterialApp first "used up" that initial route, so by the time the
    // real router mounted second, it fell back to initialLocation (register)
    // instead — sending signed-out guests to registration and signed-in
    // couples straight to their dashboard, never to the invitation.
    final isPublicInviteLink =
        Uri.base.path.startsWith('/i/') || Uri.base.path.startsWith('/g/');

    if (sessionRestore.isLoading && !isPublicInviteLink) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppColors.forestGreen,
          body: Center(
            child: CircularProgressIndicator(color: AppColors.amber),
          ),
        ),
      );
    }

    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'Wedpilot',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings.themeMode,
      scrollBehavior: _AppScrollBehavior(),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(settings.fontSizeScale),
        ),
        child: child!,
      ),
    );
  }
}
