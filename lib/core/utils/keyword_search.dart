/// Shared keyword search helpers (matches server `textSearch` behavior).
///
/// 1. Prefer the full query phrase when any item contains it.
/// 2. Otherwise match if ANY keyword appears in any field.

List<String> tokenizeSearchKeywords(String query) {
  final seen = <String>{};
  final keywords = <String>[];

  for (final raw in query.trim().split(RegExp(r'\s+'))) {
    final token = raw.replaceAll(RegExp(r'^[^A-Za-z0-9]+|[^A-Za-z0-9]+$'), '');
    if (token.length < 2) continue;
    final key = token.toLowerCase();
    if (!seen.add(key)) continue;
    keywords.add(key);
  }

  return keywords;
}

bool _haystackContainsPhrase(String haystack, String phrase) {
  final p = phrase.trim().toLowerCase();
  if (p.isEmpty) return true;
  return haystack.contains(p);
}

String _joinFields(Iterable<String?> fields) => fields
    .whereType<String>()
    .map((s) => s.toLowerCase())
    .join(' ');

/// Keyword OR only (used as fallback after phrase miss).
bool matchesSearchKeywords(String query, Iterable<String?> fields) {
  final keywords = tokenizeSearchKeywords(query);
  if (keywords.isEmpty) return true;

  final haystack = _joinFields(fields);
  return keywords.any(haystack.contains);
}

/// Phrase-first match for a single item (phrase OR keywords). Prefer
/// [filterBySearchPhraseThenKeywords] when filtering a list so phrase hits
/// exclude broader keyword-only noise.
bool matchesSearchPhraseThenKeywords(String query, Iterable<String?> fields) {
  final q = query.trim();
  if (q.isEmpty) return true;
  final haystack = _joinFields(fields);
  if (_haystackContainsPhrase(haystack, q)) return true;
  return matchesSearchKeywords(q, fields);
}

/// Filter a list: if any item matches the full phrase, return only those;
/// otherwise return keyword-OR matches.
List<T> filterBySearchPhraseThenKeywords<T>(
  Iterable<T> items,
  String query,
  Iterable<String?> Function(T item) fieldsOf,
) {
  final q = query.trim();
  if (q.isEmpty) return items.toList();

  final phraseHits = items
      .where((item) => _haystackContainsPhrase(_joinFields(fieldsOf(item)), q))
      .toList();
  if (phraseHits.isNotEmpty) return phraseHits;

  return items
      .where((item) => matchesSearchKeywords(q, fieldsOf(item)))
      .toList();
}
