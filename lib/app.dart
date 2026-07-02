import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/session_restore_provider.dart';
import 'providers/settings_provider.dart';

class WedpilotApp extends ConsumerWidget {
  const WedpilotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionRestore = ref.watch(sessionRestoreProvider);

    if (sessionRestore.isLoading) {
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
