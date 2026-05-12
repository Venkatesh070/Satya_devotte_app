// Conditional entry-point for configuring the URL strategy.
//
// On Flutter Web this delegates to `flutter_web_plugins` and installs the
// hash URL strategy (so routes live in the fragment, e.g. `/#/login`).
//
// On native platforms (Android / iOS / desktop) the implementation is a
// no-op stub. This is required because `flutter_web_plugins` transitively
// imports `dart:ui_web`, which is unavailable off the web and would fail
// the kernel build otherwise.
export 'url_strategy_stub.dart'
    if (dart.library.js_interop) 'url_strategy_web.dart';
