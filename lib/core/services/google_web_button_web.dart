import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// Google's own rendered sign-in button. Required on web: google_sign_in_web
/// throws UnimplementedError from authenticate() there, since GIS/FedCM must
/// own the click itself rather than being driven imperatively. Styled to
/// read as close as possible to the app's native "Continue with Google"
/// button (see GoogleSignInButton).
Widget renderGoogleWebButton({required double minimumWidth}) {
  return web.renderButton(
    configuration: web.GSIButtonConfiguration(
      theme: web.GSIButtonTheme.outline,
      shape: web.GSIButtonShape.pill,
      size: web.GSIButtonSize.large,
      text: web.GSIButtonText.continueWith,
      minimumWidth: minimumWidth,
    ),
  );
}
