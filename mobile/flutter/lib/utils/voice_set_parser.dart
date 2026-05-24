/// Deterministic voice → set parser.
///
/// Pure Dart, NO LLM. Given a raw speech-to-text transcript and optionally the
/// current exercise name on the active workout screen, this returns a
/// [ParsedSet] with weight (kg), reps, warmup flag, optional lift hint (only
/// set when the user named a different lift than the current one), and a
/// confidence score (0.0–1.0).
///
/// Recognised forms (case-insensitive, punctuation-tolerant):
///   - "225 for 5"                  → 225 lb / 102.06 kg, 5 reps
///   - "two twenty five by 5"       → 225 lb, 5 reps
///   - "two twenty-five for five"   → 225 lb, 5 reps
///   - "warmup set"                 → isWarmup=true (weight/reps may be null)
///   - "bench 225 for 5"            → liftHint="bench" if current ≠ bench
///   - "0 for 0"                    → 0 / 0  (valid, low-confidence)
///
/// Output weight is ALWAYS in kilograms (lb→kg = ×0.45359237). Callers convert
/// for display per the user's workout-unit preference.
library;

/// Result of parsing a single voice utterance.
class ParsedSet {
  /// Weight in kilograms. `null` when no weight was extracted.
  final double? weightKg;

  /// Rep count. `null` when no reps were extracted.
  final int? reps;

  /// True when the utterance includes a warm-up cue ("warmup", "warm up",
  /// "warm-up set", "warmup set").
  final bool isWarmup;

  /// Lift name the user spoke, but ONLY when it differs from the current
  /// exercise name. Lets the composer prompt the user to switch exercises.
  final String? liftHint;

  /// 0.0 → no usable data. 0.6 → partial (only weight OR only reps).
  /// 0.85 → fully parsed but used number-words. 1.0 → fully parsed via digits.
  final double confidence;

  const ParsedSet({
    this.weightKg,
    this.reps,
    this.isWarmup = false,
    this.liftHint,
    this.confidence = 0.0,
  });

  @override
  String toString() =>
      'ParsedSet(weightKg=$weightKg, reps=$reps, isWarmup=$isWarmup, '
      'liftHint=$liftHint, confidence=$confidence)';
}

/// Pure parser. Stateless — safe to use as a const-constructed singleton.
class VoiceSetParser {
  const VoiceSetParser();

  static const double _lbToKg = 0.45359237;

  // ---- Number-word lookup ----------------------------------------------------

  static const Map<String, int> _ones = {
    'zero': 0,
    'oh': 0, // "two-oh-five" → 205
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
    'eleven': 11,
    'twelve': 12,
    'thirteen': 13,
    'fourteen': 14,
    'fifteen': 15,
    'sixteen': 16,
    'seventeen': 17,
    'eighteen': 18,
    'nineteen': 19,
  };

  static const Map<String, int> _tens = {
    'twenty': 20,
    'thirty': 30,
    'forty': 40,
    'fifty': 50,
    'sixty': 60,
    'seventy': 70,
    'eighty': 80,
    'ninety': 90,
  };

  // Lifts the parser will recognise as a liftHint. Lowercase, single-token or
  // short multi-token canonical forms. Extend as needed; intentionally limited
  // to the common big lifts so unrelated words don't get misread as a lift.
  static const List<String> _knownLifts = [
    'bench',
    'bench press',
    'squat',
    'back squat',
    'front squat',
    'deadlift',
    'dead lift',
    'ohp',
    'overhead press',
    'press',
    'row',
    'barbell row',
    'pull up',
    'pullup',
    'pull-up',
    'chin up',
    'chinup',
    'curl',
    'bicep curl',
    'tricep extension',
    'lunge',
    'rdl',
    'romanian deadlift',
    'hip thrust',
    'leg press',
    'lat pulldown',
    'pulldown',
  ];

  // ---- Public API ------------------------------------------------------------

  ParsedSet parse(String transcript, {String? currentExerciseName}) {
    final raw = transcript.trim();
    if (raw.isEmpty) return const ParsedSet();

    // Normalise: lowercase, strip punctuation except digits/dots/hyphens, then
    // collapse hyphens between number-words ("twenty-five" → "twenty five").
    var t = raw.toLowerCase();
    t = t.replaceAll(RegExp(r'[,;:!?]'), ' ');
    // Hyphen between letters → space (twenty-five). Keep numeric hyphens out
    // of weight (no negatives expected).
    t = t.replaceAllMapped(
      RegExp(r'([a-z])-([a-z])'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();

    final isWarmup = RegExp(r'\bwarm\s?up\b').hasMatch(t);

    // Lift detection (longest match wins, so "bench press" beats "press").
    String? liftHint;
    final sortedLifts = [..._knownLifts]
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final lift in sortedLifts) {
      if (RegExp('\\b${RegExp.escape(lift)}\\b').hasMatch(t)) {
        final canonical = _canonicalLift(lift);
        final currentCanonical = currentExerciseName == null
            ? null
            : _canonicalLift(currentExerciseName.toLowerCase());
        if (currentCanonical == null || !currentCanonical.contains(canonical)) {
          liftHint = canonical;
        }
        break;
      }
    }

    // --- Try DIGIT form first: "225 for 5", "225x5", "225 by 5", "225 lb 5 reps"
    final digitMatch = RegExp(
      r'(\d+(?:\.\d+)?)\s*(?:lb|lbs|pound|pounds|kg|kgs|kilo|kilos)?\s*'
      r'(?:x|by|for|@)\s*(\d+)\s*(?:rep|reps)?',
    ).firstMatch(t);
    if (digitMatch != null) {
      final weight = double.tryParse(digitMatch.group(1)!);
      final reps = int.tryParse(digitMatch.group(2)!);
      final isKg = RegExp(r'\d+(?:\.\d+)?\s*(?:kg|kgs|kilo|kilos)\b')
          .hasMatch(t);
      if (weight != null && reps != null) {
        return ParsedSet(
          weightKg: isKg ? weight : weight * _lbToKg,
          reps: reps,
          isWarmup: isWarmup,
          liftHint: liftHint,
          confidence: 1.0,
        );
      }
    }

    // --- Try WORD form: tokenize, walk left→right, build (weight, reps).
    final tokens = t.split(' ');
    final (wordWeight, wordReps, usedWords) =
        _extractWordWeightAndReps(tokens);
    if (wordWeight != null && wordReps != null) {
      // Detect explicit kg in the words.
      final isKg = RegExp(r'\b(kg|kgs|kilo|kilos)\b').hasMatch(t);
      return ParsedSet(
        weightKg: isKg ? wordWeight.toDouble() : wordWeight * _lbToKg,
        reps: wordReps,
        isWarmup: isWarmup,
        liftHint: liftHint,
        confidence: usedWords ? 0.85 : 1.0,
      );
    }

    // --- Partial parse: a lone weight OR a lone rep count.
    final loneWeight = _firstNumberLike(tokens);
    final loneReps = _findRepsOnly(t, tokens);
    if (loneWeight != null || loneReps != null || isWarmup || liftHint != null) {
      final isKg = RegExp(r'\b(kg|kgs|kilo|kilos)\b').hasMatch(t);
      return ParsedSet(
        weightKg: loneWeight == null
            ? null
            : (isKg ? loneWeight.toDouble() : loneWeight * _lbToKg),
        reps: loneReps,
        isWarmup: isWarmup,
        liftHint: liftHint,
        // Pure warmup / lift-only with no numbers → still 0.6 (low) so the
        // composer can decide to merge with a follow-up utterance.
        confidence: (loneWeight != null && loneReps != null) ? 1.0 : 0.6,
      );
    }

    return const ParsedSet();
  }

  // ---- Internals -------------------------------------------------------------

  /// Canonicalise a lift phrase ("bench press" → "bench press"; "pullup" →
  /// "pull up"). Keeps things readable for the liftHint surfaced to the UI.
  String _canonicalLift(String lift) {
    final l = lift.replaceAll('-', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    switch (l) {
      case 'pullup':
        return 'pull up';
      case 'chinup':
        return 'chin up';
      case 'dead lift':
        return 'deadlift';
      case 'ohp':
        return 'overhead press';
      default:
        return l;
    }
  }

  /// Returns (weight, reps, usedNumberWords). Walks tokens to find a
  /// number (digit or word) followed by a separator (for/by/x/@) and another
  /// number. Falls back to two consecutive numbers separated only by whitespace.
  (int?, int?, bool) _extractWordWeightAndReps(List<String> tokens) {
    // Build a list of (startIdx, endIdx, value, isWord) for every contiguous
    // number we can extract.
    final numbers = <_NumSpan>[];
    int i = 0;
    while (i < tokens.length) {
      final tok = tokens[i];
      // Digit?
      final asDigit = int.tryParse(tok);
      if (asDigit != null) {
        numbers.add(_NumSpan(i, i, asDigit, false));
        i++;
        continue;
      }
      // Number-word run starting here?
      final wordRun = _consumeNumberWords(tokens, i);
      if (wordRun != null) {
        numbers.add(_NumSpan(i, wordRun.endIdx, wordRun.value, true));
        i = wordRun.endIdx + 1;
        continue;
      }
      i++;
    }

    if (numbers.length < 2) return (null, null, false);

    // Find a (weight, reps) pair: prefer two numbers with a separator token
    // between them (for/by/x/@); else first two numbers in order.
    const separators = {'for', 'by', 'x', '@', 'times'};
    for (var p = 0; p < numbers.length - 1; p++) {
      final a = numbers[p];
      final b = numbers[p + 1];
      final between = tokens
          .sublist(a.endIdx + 1, b.startIdx)
          .where((s) => s.isNotEmpty)
          .toList();
      final hasSep = between.any(separators.contains);
      // Accept pair if separator present OR they're adjacent OR only unit
      // words sit between them ("225 pounds 5 reps").
      const units = {'lb', 'lbs', 'pound', 'pounds', 'kg', 'kgs', 'kilo',
        'kilos', 'rep', 'reps'};
      final onlyUnits = between.every(units.contains);
      if (hasSep || between.isEmpty || onlyUnits) {
        final usedWords = a.isWord || b.isWord;
        return (a.value, b.value, usedWords);
      }
    }
    // Fallback: first two numbers regardless.
    final a = numbers[0];
    final b = numbers[1];
    return (a.value, b.value, a.isWord || b.isWord);
  }

  /// Consume a contiguous run of number-words starting at [start]. Returns
  /// null if [tokens[start]] isn't a number-word. Handles:
  ///   - "five"                       → 5
  ///   - "twenty five"                → 25
  ///   - "two twenty five"            → 225  (hundreds-implicit)
  ///   - "two hundred twenty five"    → 225
  ///   - "one hundred"                → 100
  ///   - "two oh five"                → 205
  _NumRun? _consumeNumberWords(List<String> tokens, int start) {
    int idx = start;
    int end = start;
    int? acc;

    int? readUnderHundred(int from) {
      if (from >= tokens.length) return null;
      final t = tokens[from];
      if (_tens.containsKey(t)) {
        var val = _tens[t]!;
        // Next can be a ones word → 25
        if (from + 1 < tokens.length && _ones.containsKey(tokens[from + 1])) {
          val += _ones[tokens[from + 1]]!;
          end = from + 1;
          return val;
        }
        end = from;
        return val;
      }
      if (_ones.containsKey(t)) {
        end = from;
        return _ones[t]!;
      }
      return null;
    }

    // Step 1: leading ones/teens or tens
    final first = readUnderHundred(idx);
    if (first == null) return null;
    acc = first;
    idx = end + 1;

    // Step 2: explicit "hundred"
    if (idx < tokens.length && tokens[idx] == 'hundred') {
      acc = (acc) * 100;
      end = idx;
      idx = end + 1;
      // Optional remainder under 100
      final rest = readUnderHundred(idx);
      if (rest != null) {
        acc += rest;
        idx = end + 1;
      }
      return _NumRun(end, acc);
    }

    // Step 3: implicit hundreds ("two twenty five" → 225, "two oh five" → 205)
    if (acc <= 9 && idx < tokens.length) {
      // Pattern A: digit + tens [+ ones]  → "two twenty five"
      final under = readUnderHundred(idx);
      if (under != null) {
        acc = acc * 100 + under;
        return _NumRun(end, acc);
      }
      // Pattern B: digit + "oh" + ones  → handled above via readUnderHundred
      // ("oh" is in _ones as 0, so "two oh five" becomes 2 then we'd try to
      // read "oh five" which yields 0 then we'd skip "five"). Special-case:
      if (idx + 1 < tokens.length &&
          tokens[idx] == 'oh' &&
          _ones.containsKey(tokens[idx + 1])) {
        acc = acc * 100 + _ones[tokens[idx + 1]]!;
        end = idx + 1;
        return _NumRun(end, acc);
      }
    }

    // [consumed] is guaranteed true here — the leading readUnderHundred above
    // returns early if no number-word matched.
    return _NumRun(end, acc);
  }

  int? _firstNumberLike(List<String> tokens) {
    for (var i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      final d = int.tryParse(t);
      if (d != null) return d;
      final run = _consumeNumberWords(tokens, i);
      if (run != null) return run.value;
    }
    return null;
  }

  /// Detect bare rep cues like "5 reps", "for 5", "five reps".
  int? _findRepsOnly(String full, List<String> tokens) {
    final m = RegExp(r'(\d+)\s*(?:rep|reps)\b').firstMatch(full);
    if (m != null) return int.tryParse(m.group(1)!);
    final mFor = RegExp(r'\bfor\s+(\d+)\b').firstMatch(full);
    if (mFor != null) return int.tryParse(mFor.group(1)!);
    // Word form: "for five"
    for (var i = 0; i < tokens.length - 1; i++) {
      if (tokens[i] == 'for') {
        final run = _consumeNumberWords(tokens, i + 1);
        if (run != null) return run.value;
        final d = int.tryParse(tokens[i + 1]);
        if (d != null) return d;
      }
    }
    return null;
  }
}

class _NumSpan {
  final int startIdx;
  final int endIdx;
  final int value;
  final bool isWord;
  const _NumSpan(this.startIdx, this.endIdx, this.value, this.isWord);
}

class _NumRun {
  final int endIdx;
  final int value;
  const _NumRun(this.endIdx, this.value);
}
