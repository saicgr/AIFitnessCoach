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
///   - A parenthetical that runs on into the previous word without a space
///     ("squat(back)") gets the missing space inserted ("squat (back)").
///   - The first letter after a delimiter like '(' is capitalized too
///     ("(pro lat bar)" -> "(Pro Lat Bar)"), and the function is idempotent:
///     feeding it already-correct output returns the same string unchanged.
///
/// C5 fix: many exercises (notably "wide push ups bodyweight" seen in
/// production) ship lowercase from the DB. Apply this at every render
/// site rather than relying on backend hygiene alone.
///
/// E2E #48: capWord() used to split only on whitespace and only look at
/// index 0, so 'cable pulldown (pro lat bar)' rendered as
/// 'Cable Pulldown (pro Lat Bar)' (letter after '(' never capitalized),
/// 'barbell full squat(back)' kept the missing space, and re-running the
/// function on already-correct '(Pro Lat Bar)' re-lowercased it to
/// '(pro Lat Bar)'. Fixed by inserting the missing space before '(' and by
/// capitalizing/preserving at the first *letter* in a token rather than at
/// character index 0.
String toExerciseTitleCase(String input) {
  if (input.isEmpty) return input;
  const smallWords = {'and', 'or', 'the', 'of', 'to', 'a', 'in', 'on', 'for', 'with'};
  const acronyms = {'ez', 'db', 'kb', 'trx', 'bb', 't', 'srl'};

  String capWord(String w) {
    if (w.isEmpty) return w;
    // Numbers / number-prefixed pass through (e.g. "21s", "5x5", "1rm").
    if (RegExp(r'^[0-9]').hasMatch(w)) return w;

    // Find the first actual letter, skipping leading delimiters such as
    // '(', '"', etc. so we capitalize/preserve the word itself rather than
    // the punctuation glued to it.
    final firstLetter = RegExp(r'[A-Za-z]').firstMatch(w);
    if (firstLetter == null) return w; // no letters at all (pure punctuation)
    final idx = firstLetter.start;
    final prefix = w.substring(0, idx);
    final rest = w.substring(idx);

    final lower = rest.toLowerCase();
    if (acronyms.contains(lower)) return prefix + rest.toUpperCase();

    // Preserve already-Capitalized tokens (proper nouns, brand names) --
    // and this also makes the function idempotent on its own output.
    final firstChar = rest[0];
    if (rest.length > 1 && firstChar == firstChar.toUpperCase() && firstChar != firstChar.toLowerCase()) {
      return prefix + rest;
    }
    return prefix + firstChar.toUpperCase() + rest.substring(1).toLowerCase();
  }

  String capHyphenated(String segment) {
    if (!segment.contains('-')) return capWord(segment);
    return segment.split('-').map(capWord).join('-');
  }

  // Insert a missing space before '(' when it runs on directly from the
  // previous character, e.g. "squat(back)" -> "squat (back)". Leaves
  // already-spaced/leading '(' alone so this stays idempotent.
  final normalized = input.replaceAllMapped(
    RegExp(r'([^\s(])(\()'),
    (m) => '${m[1]} (',
  );

  final tokens = normalized.split(RegExp(r'\s+'));
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
