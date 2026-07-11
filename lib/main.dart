import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
