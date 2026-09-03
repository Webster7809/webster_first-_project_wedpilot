// The real implementation binds directly to Google's Identity Services JS
// SDK (dart:ui_web / package:web / google_identity_services_web), which only
// compile for the web target — so it's swapped in via a conditional export
// rather than an unconditional import here.
export 'google_web_button_stub.dart'
    if (dart.library.js_util) 'google_web_button_web.dart';
