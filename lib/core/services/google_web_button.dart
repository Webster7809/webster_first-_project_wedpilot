// google_sign_in_web imports dart:ui_web / package:web, which only compile
// for the web target — so the real implementation is swapped in via a
// conditional export rather than an unconditional import here.
export 'google_web_button_stub.dart'
    if (dart.library.js_util) 'google_web_button_web.dart';
