import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Path URLs (e.g. /g/token) instead of hash URLs (/#/g/token) — a shared
  // invite link's `#` fragment is silently dropped by some SMS/messaging
  // apps' auto-linkifiers (they treat `#` as a hashtag boundary), which sent
  // guests to the app's default route instead of their invitation. No-op on
  // non-web platforms. The server-side SPA fallback (docker/nginx.conf)
  // already serves index.html for any path, so this needs no hosting change.
  usePathUrlStrategy();
  await initializeDateFormatting();
  await Hive.initFlutter();
  await Hive.openBox('app_settings');
  await Hive.openBox('invitation_drafts');
  runApp(
    const ProviderScope(
      child: WedpilotApp(),
    ),
  );
}
