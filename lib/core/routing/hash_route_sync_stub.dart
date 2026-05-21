/// Non-web: optional no-op (CMS shell uses in-memory tab state only).
void updateCmsHashRoute(String route) {}

/// Non-web: no hash listener.
void Function() listenCmsHashRoute(void Function(String route) onChanged) =>
    () {};
