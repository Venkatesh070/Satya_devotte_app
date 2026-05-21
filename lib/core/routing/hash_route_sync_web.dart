// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Updates the browser hash (e.g. `/#/cms/admins`) without a full GetX navigation.
void updateCmsHashRoute(String route) {
  final path = route.startsWith('/') ? route : '/$route';
  final target = '#$path';
  if (html.window.location.hash != target) {
    html.window.history.pushState(null, '', target);
  }
}

/// Fires when the user uses browser back/forward (hash changes).
void Function() listenCmsHashRoute(void Function(String route) onChanged) {
  void handler(html.Event _) {
    onChanged(_hashRouteFromWindow());
  }

  html.window.addEventListener('popstate', handler);
  html.window.addEventListener('hashchange', handler);
  return () {
    html.window.removeEventListener('popstate', handler);
    html.window.removeEventListener('hashchange', handler);
  };
}

String _hashRouteFromWindow() {
  final hash = html.window.location.hash;
  if (hash.isEmpty || hash == '#') return '/';
  return hash.startsWith('#') ? hash.substring(1) : hash;
}
