import 'dart:async';

/// Debounces keystrokes and throttles how often [onSearch] runs (e.g. API calls).
class CmsSearchScheduler {
  CmsSearchScheduler({
    required this.onSearch,
    this.debounce = const Duration(milliseconds: 400),
    this.throttle = const Duration(milliseconds: 800),
  });

  final void Function(String query) onSearch;
  final Duration debounce;
  final Duration throttle;

  Timer? _debounceTimer;
  DateTime? _lastSearchAt;
  String _pending = '';

  void onQueryChanged(String value) {
    _pending = value;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, _flushAfterDebounce);
  }

  /// Run search immediately (Enter, clear button).
  void searchNow(String value) {
    _pending = value;
    _debounceTimer?.cancel();
    _lastSearchAt = DateTime.now();
    onSearch(_pending);
  }

  void dispose() {
    _debounceTimer?.cancel();
  }

  void _flushAfterDebounce() {
    final now = DateTime.now();
    if (_lastSearchAt != null) {
      final elapsed = now.difference(_lastSearchAt!);
      if (elapsed < throttle) {
        _debounceTimer?.cancel();
        _debounceTimer = Timer(throttle - elapsed, _invoke);
        return;
      }
    }
    _invoke();
  }

  void _invoke() {
    _lastSearchAt = DateTime.now();
    onSearch(_pending);
  }
}
