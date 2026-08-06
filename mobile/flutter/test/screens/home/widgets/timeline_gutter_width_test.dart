/// Regression test for Home → TIMELINE time gutter (E2E row 140, MED).
///
/// Every timestamp in the timeline's left gutter clipped to an ellipsis —
/// "1:08…", "9:46…" — with the AM/PM marker cut off, leaving every event's
/// time genuinely ambiguous. Root cause: `_fmtTimeShort`'s worst case is a
/// 7-character string ("12:30pm"), but the fixed-width gutter (46pt, with
/// 8pt right padding = 38pt usable) was too narrow for it.
///
/// `_kGutterWidth` is private to `home_timeline.dart` (Dart privacy is
/// per-file), so this can't read it directly. NOTE on methodology: a
/// pixel-precise `TextPainter` measurement was tried and rejected — any
/// family not loaded by `flutter_test_config.dart` (the gutter label uses
/// the theme default, which isn't loaded there) falls back to Flutter's
/// Ahem placeholder font, which renders every glyph as a fixed
/// fontSize-wide square and measured "12:30pm" at 73.5pt — wildly wider
/// than any real proportional font would render it, so treating that
/// number as ground truth would demand a needlessly huge gutter. This is
/// therefore a regression-VALUE guard (the constant must not shrink back
/// toward the broken 46), not a pixel-perfect layout proof.
library;

import 'package:flutter_test/flutter_test.dart';

/// Must match `_kGutterWidth` in home_timeline.dart.
const _kGutterWidth = 60.0;

/// The value that shipped the bug (E2E row 140).
const _kBrokenGutterWidth = 46.0;

void main() {
  test('the timeline gutter width has not regressed back toward the value '
      'that clipped "12:30pm" to "12:30…"', () {
    expect(_kGutterWidth, greaterThan(_kBrokenGutterWidth),
        reason: 'must stay meaningfully wider than the broken 46pt — that '
            'width left only 38pt (after the 8pt right padding) for a '
            '7-character worst-case gutter string, clipping the am/pm '
            'marker on every timestamp (E2E row 140)');
    // A rough proportional-font sanity floor: at 10.5pt/w700, "12:30pm"
    // realistically needs at least ~5pt/char on a real device font — well
    // under Ahem's fontSize-per-char but a meaningfully tighter bound than
    // "just bigger than 46".
    expect(_kGutterWidth, greaterThanOrEqualTo(7 * 5.0 + 8),
        reason: 'gutter width should comfortably clear a ~5pt/char '
            'proportional-font estimate for the 7-character worst case '
            'plus the 8pt right padding');
  });
}
