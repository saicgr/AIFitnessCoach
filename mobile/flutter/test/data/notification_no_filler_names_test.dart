// Gate: notifications must never address the user by a generic filler name.
//
// A real device received "Your Week in Review, Champ!". This project's rule is
// that notifications carry REAL personal data — the user's name, their actual
// numbers — never a mail-merge placeholder. 113 such strings existed across
// four coach personas.
//
// The distinction this test encodes, and the reason it is not just a
// blanket word-ban: a VOCATIVE ("Drink up, champ!", "MOVE IT, Soldier!")
// addresses the reader and is filler. A third-person statement in the coach's
// own voice ("A dehydrated soldier is a weak soldier", "Breakfast of
// Champions!") is characterisation, not a placeholder, and deleting it would
// gut the personas for no benefit. So this matches the ADDRESS forms only.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Terms that have appeared as vocatives in this codebase, plus the usual
/// suspects a future template might reach for.
const _fillerTerms = [
  'champ', 'soldier', 'bestie', 'babe', 'babes', 'baby',
  'bruh', 'bro', 'fam', 'superstar', 'buddy', 'legend',
  'friend', 'chief', 'boss', 'rockstar', 'warrior', 'beast',
];

/// A filler word used as ADDRESS: preceded by a comma/greeting, or trailing
/// before ! ? or end-of-string. Deliberately does NOT match "a soldier who…"
/// or "Breakfast of Champions".
final _vocative = RegExp(
  r'(,\s*(' + _fillerTerms.join('|') + r')\b)'
  r'|(\b(hey|hi|hello|yo|ok|okay|listen|alright)\s+(' + _fillerTerms.join('|') + r')\b)'
  r"|(\b(" + _fillerTerms.join('|') + r")\s*[!?.]\s*$)",
  caseSensitive: false,
);

void main() {
  test('no notification template addresses the user by a filler name', () {
    final file =
        File('lib/data/models/coach_notification_templates.dart');
    expect(file.existsSync(), isTrue, reason: 'run from mobile/flutter');

    final offenders = <String>[];
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trimLeft();
      // Section headers document the persona's theme word; not user-facing.
      if (trimmed.startsWith('//') || trimmed.startsWith('///')) continue;
      if (_vocative.hasMatch(line)) {
        offenders.add('${file.path}:${i + 1}: ${trimmed.trim()}');
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'These address the user by a placeholder instead of their name.\n'
          'Drop the term of address entirely — a title with no name reads '
          'fine ("Your Week in Review!"); one with "Champ" reads like a '
          'failed mail-merge. Do NOT substitute another filler or add a '
          "`?? 'Champ'` default.\n  ${offenders.join('\n  ')}",
    );
  });

  test('no filler word is used as a fallback for a missing name', () {
    // The failure mode this guards is subtler than the literal above: a
    // personalization helper that "gracefully" degrades to a placeholder
    // reintroduces exactly the reported bug for every user without a name.
    final files = [
      File('lib/data/models/coach_notification_templates.dart'),
      File('lib/data/services/notification_service_ext_ext.dart'),
      File('lib/data/services/notification_service.dart'),
    ];
    final fallback = RegExp(
      r"\?\?\s*'(" + _fillerTerms.join('|') + r")'",
      caseSensitive: false,
    );
    final offenders = <String>[];
    for (final f in files) {
      if (!f.existsSync()) continue;
      final lines = f.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (fallback.hasMatch(lines[i])) {
          offenders.add('${f.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
    expect(offenders, isEmpty,
        reason: 'A missing name must drop the address, not substitute one:\n'
            '  ${offenders.join('\n  ')}');
  });

  test('the vocative matcher is not vacuous', () {
    // Proves the regex can actually fail — the #141 gate sat green-looking
    // and broken for weeks because nothing checked it could still catch.
    expect(_vocative.hasMatch("'Drink up, champ!'"), isTrue);
    expect(_vocative.hasMatch("'MOVE IT, Soldier!'"), isTrue);
    expect(_vocative.hasMatch("'Hey Champ!'"), isTrue);
    expect(_vocative.hasMatch("'GOOD MORNING BESTIE'"), isFalse,
        reason: 'no comma/greeting/terminator — covered by the sweep, not here');
    // …and that it leaves legitimate persona voice alone.
    expect(
        _vocative.hasMatch("'A dehydrated soldier is a weak soldier. Fix that.'"),
        isFalse);
    expect(_vocative.hasMatch("'Breakfast of Champions!'"), isFalse);
    expect(
        _vocative
            .hasMatch("'No soldier leaves a job unfinished.'"),
        isFalse);
  });
}
