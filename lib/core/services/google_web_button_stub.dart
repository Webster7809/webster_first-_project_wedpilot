import 'package:flutter/widgets.dart';

/// Non-web stub, swapped out for the real implementation by the conditional
/// export in google_web_button.dart. GoogleSignInButton only reaches this
/// path when kIsWeb, so none of this should ever actually run.
Widget renderGoogleWebButton({required double minimumWidth}) {
  throw StateError('renderGoogleWebButton is web-only.');
}

Future<void> ensureGoogleWebInitialized() {
  throw StateError('ensureGoogleWebInitialized is web-only.');
}

Stream<String> get googleWebIdTokenEvents =>
    throw StateError('googleWebIdTokenEvents is web-only.');
