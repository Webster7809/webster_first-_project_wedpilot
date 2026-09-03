import 'package:flutter/widgets.dart';

/// Non-web stub, swapped out for the real implementation by the conditional
/// export in google_web_button.dart. GoogleSignInButton only reaches this
/// path when kIsWeb, so this should never actually run.
Widget renderGoogleWebButton({required double minimumWidth}) {
  throw StateError('renderGoogleWebButton is web-only.');
}
