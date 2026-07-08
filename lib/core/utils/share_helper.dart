import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../widgets/wed_snack_bar.dart';

/// Shares [text] via the platform share sheet, guaranteeing the user is
/// never fully blocked from sharing: if the native share sheet throws
/// (unavailable, denied, etc.) this falls back to copying [text] to the
/// clipboard and confirms via a snackbar.
///
/// IMPORTANT (web gesture rule): call this synchronously from the
/// triggering onPressed/onTap handler whenever the text to share is
/// already known — do NOT `await` any network call before calling this,
/// or the browser's Web Share API will silently refuse to open because
/// the user-gesture context has already expired by the time this runs.
Future<void> shareWithFallback(
  BuildContext context, {
  required String text,
  String? subject,
}) async {
  try {
    await Share.share(text, subject: subject);
  } catch (_) {
    if (!context.mounted) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    showWedSnackBar(
      context,
      'Could not open the share sheet — link copied to clipboard instead.',
      type: SnackType.info,
    );
  }
}
