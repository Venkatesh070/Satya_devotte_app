// Web implementation: installs the hash URL strategy so routes live in the
// fragment (e.g. `/#/login`) instead of being requested as real paths from
// the static server (which would 404 without an SPA fallback).
import 'package:flutter_web_plugins/url_strategy.dart';

void configureUrlStrategy() {
  setUrlStrategy(const HashUrlStrategy());
}
