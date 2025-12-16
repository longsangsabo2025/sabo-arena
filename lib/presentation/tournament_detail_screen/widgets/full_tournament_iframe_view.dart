// This file delegates to a platform-specific implementation.
// For web builds the actual implementation (which uses `dart:html`) is
// provided in `full_tournament_iframe_view_web.dart`.
// For non-web builds a mobile-friendly fallback is provided in
// `full_tournament_iframe_view_mobile.dart`.

export 'full_tournament_iframe_view_mobile.dart'
    if (dart.library.html) 'full_tournament_iframe_view_web.dart';
