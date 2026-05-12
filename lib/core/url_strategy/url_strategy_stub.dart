// No-op implementation used on non-web platforms.
//
// Native targets (Android / iOS / desktop) never load
// `package:flutter_web_plugins`, so they cannot reference
// `setUrlStrategy` or `HashUrlStrategy`. Calling this function on
// those platforms is intentionally a no-op.
void configureUrlStrategy() {}
