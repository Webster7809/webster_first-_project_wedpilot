import 'dart:async';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:google_identity_services_web/id.dart' as gis;
import 'package:google_identity_services_web/loader.dart' as gis_loader;
import 'package:web/web.dart' as web;

import '../config/api_config.dart';

// Talks to Google's Identity Services JS SDK directly rather than going
// through google_sign_in_web. That plugin hardcodes auto_select: true with
// no way to override it from the public Dart API, which makes its rendered
// button silently switch to a personalized "Continue as [name]" state
// whenever the browser already has a Google session — this reimplements
// initialize()/renderButton() with auto_select: false instead, so the
// button always reads "Continue with Google". See GOOGLE_SIGNIN_SETUP.md.

const String _viewType = 'gsi_login_button';

final StreamController<String> _idTokenController =
    StreamController<String>.broadcast();

/// ID tokens reported once a sign-in completes — Google's rendered button
/// (built in [renderGoogleWebButton]) drives the click itself, so this is
/// the only way the app learns of a result.
Stream<String> get googleWebIdTokenEvents => _idTokenController.stream;

Future<void>? _initFuture;

/// Starts (or awaits an already-started) initialization of the GIS SDK.
/// Safe to call repeatedly; only runs once per page load.
Future<void> ensureGoogleWebInitialized() {
  return _initFuture ??= _init();
}

Future<void> _init() async {
  // Registered once per page load, not per widget build — the registry
  // throws if the same viewType is registered twice.
  ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
    final web.Element element = web.document.createElement('div');
    element.setAttribute(
      'style',
      'width: 100%; height: 100%; overflow: hidden; display: flex; '
          'align-items: center; justify-content: center;',
    );
    return element;
  });

  await gis_loader.loadWebSdk();
  gis.id.initialize(
    gis.IdConfiguration(
      client_id: ApiConfig.googleServerClientId,
      auto_select: false,
      callback: _handleCredentialResponse,
    ),
  );
}

void _handleCredentialResponse(gis.CredentialResponse response) {
  final String? idToken = response.credential;
  if (idToken != null) {
    _idTokenController.add(idToken);
  }
}

/// Google's own rendered sign-in button. Required on web: the SDK must own
/// the click itself (GIS/FedCM), rather than being driven imperatively.
Widget renderGoogleWebButton({required double minimumWidth}) {
  return FutureBuilder<void>(
    future: ensureGoogleWebInitialized(),
    builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const SizedBox(height: 40);
      }
      return SizedBox(
        width: minimumWidth,
        height: 40,
        child: HtmlElementView(
          viewType: _viewType,
          onPlatformViewCreated: (int viewId) {
            final web.Element element =
                ui_web.platformViewRegistry.getViewById(viewId) as web.Element;
            gis.id.renderButton(
              element,
              gis.GsiButtonConfiguration(
                type: gis.ButtonType.standard,
                theme: gis.ButtonTheme.outline,
                size: gis.ButtonSize.large,
                text: gis.ButtonText.continue_with,
                shape: gis.ButtonShape.pill,
                width: minimumWidth,
              ),
            );
          },
        ),
      );
    },
  );
}
