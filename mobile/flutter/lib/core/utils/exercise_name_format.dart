/// Title-cases exercise names for display.
///
/// Rules:
///   - Lowercase tokens like 'and', 'or', 'the', 'of', 'to', 'a', 'in',
///     'on', 'for', 'with' stay lowercase UNLESS they're the first token.
///   - Known acronyms ("EZ", "DB", "KB", "TRX", "BB", "T") render uppercase
///     even if the source string had them mixed-case.
///   - Hyphenated tokens ("pull-up") capitalize each segment ("Pull-Up").
///   - Already-capitalized tokens are preserved (don't downgrade
///     "Bulgarian", "Romanian", "Smith", etc.).
///   - Tokens that start with a digit ("21s", "5×5") pass through unchanged.
///
/// C5 fix: many exercises (notably "wide push ups bodyweight" seen in
/// production) ship lowercase from the DB. Apply this at every render
/// site rather than relying on backend hygiene alone.
String toExerciseTitleCase(String input) {
  if (input.isEmpty) return input;
  const smallWords = {'and', 'or', 'the', 'of', 'to', 'a', 'in', 'on', 'for', 'with'};
  const acronyms = {'ez', 'db', 'kb', 'trx', 'bb', 't', 'srl'};

  String capWord(String w) {
    if (w.isEmpty) return w;
    // Numbers / number-prefixed pass through (e.g. "21s", "5x5", "1rm").
    if (RegExp(r'^[0-9]').hasMatch(w)) return w;
    final lower = w.toLowerCase();
    if (acronyms.contains(lower)) return w.toUpperCase();
    // Preserve already-Capitalized tokens (proper nouns, brand names).
    if (w.length > 1 && w[0] == w[0].toUpperCase() && w[0] != w[0].toLowerCase()) {
      return w;
    }
    return w[0].toUpperCase() + w.substring(1).toLowerCase();
  }

  String capHyphenated(String segment) {
    if (!segment.contains('-')) return capWord(segment);
    return segment.split('-').map(capWord).join('-');
  }

  final tokens = input.split(RegExp(r'\s+'));
  final out = <String>[];
  for (var i = 0; i < tokens.length; i++) {
    final t = tokens[i];
    if (t.isEmpty) continue;
    final lower = t.toLowerCase();
    if (i > 0 && smallWords.contains(lower)) {
      out.add(lower);
    } else {
      out.add(capHyphenated(t));
    }
  }
  return out.join(' ');
}

extension ExerciseNameTitleCase on String {
  /// Display-only Title Case for exercise names. See [toExerciseTitleCase].
  String get titleCaseExercise => toExerciseTitleCase(this);
}
