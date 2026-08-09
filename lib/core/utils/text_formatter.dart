// lib/core/utils/text_formatter.dart

/// Splits a prose description/uses field (e.g. `medicinal_uses`,
/// `ecological_importance`) into short, independently-readable bullet
/// points — the DB stores these as full sentences/clauses, not a list, so
/// this is a display-time transform, not a schema change.
///
/// Splits on semicolons or on a period directly followed by whitespace —
/// the natural clause separators in this content — while the lookbehind
/// (requires a letter/digit/`)` right before the separator) keeps
/// mid-number periods like "1.5 metres" or "3:1" intact, since those are
/// never followed by whitespace immediately after the punctuation mark
/// either. Fragments of 8 characters or fewer are dropped as noise rather
/// than shown as a bare, uninformative bullet.
List<String> toBullets(String text) {
  if (text.trim().isEmpty) return [];

  final raw = text
      .split(RegExp(r'(?<=[a-zA-Z0-9\)])[.;]\s+'))
      .map((s) => s.trim())
      .where((s) => s.length > 8)
      .toList();

  return raw.map((s) {
    final bullet = s[0].toUpperCase() + s.substring(1);
    if (bullet.endsWith('.') || bullet.endsWith('!') || bullet.endsWith('?')) {
      return bullet;
    }
    return '$bullet.';
  }).toList();
}
