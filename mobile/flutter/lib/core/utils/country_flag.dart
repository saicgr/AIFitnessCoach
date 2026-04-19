/// Convert an ISO-3166-1 alpha-2 country code into its emoji flag.
///
/// Flag emojis are built from two regional-indicator code points (one per
/// letter). `A` = U+1F1E6, so we offset each letter's ASCII value. Returns
/// null for invalid / empty input so callers can conditionally render a
/// `Text` widget without a surrounding null check.
String? flagFor(String? iso2) {
  if (iso2 == null) return null;
  final code = iso2.trim().toUpperCase();
  if (code.length != 2) return null;

  final a = code.codeUnitAt(0);
  final b = code.codeUnitAt(1);
  // Must be A-Z
  if (a < 0x41 || a > 0x5A || b < 0x41 || b > 0x5A) return null;

  const regionalIndicatorA = 0x1F1E6;
  final ra = regionalIndicatorA + (a - 0x41);
  final rb = regionalIndicatorA + (b - 0x41);
  return String.fromCharCodes([ra, rb]);
}
