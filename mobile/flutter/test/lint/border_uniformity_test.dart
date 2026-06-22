import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Guard against a paint-time crash that has shipped three times:
///
///   "A borderRadius can only be given on borders with uniform colors."
///
/// Flutter throws this at PAINT (so `flutter analyze` can't catch it) when a
/// `BoxDecoration` combines a `borderRadius` with a `Border(...)` whose sides
/// have **different** colors (e.g. an orange top + gray sides). A single-side
/// `Border(top: ...)` is fine; the danger is ≥2 sides with differing colors.
///
/// This test scans lib/ source and fails listing every offending decoration so
/// the fix (use `Border.all(...)`, or a top-only border, or a ClipRRect + a
/// separate accent line) is made before it can reach a device.
void main() {
  test('no BoxDecoration mixes a non-uniform Border with borderRadius', () {
    final libDir = Directory('lib');
    final offenders = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final src = entity.readAsStringSync();

      for (final m in RegExp(r'BoxDecoration\(').allMatches(src)) {
        final block = _balanced(src, m.end - 1);
        if (block == null || !block.contains('borderRadius')) continue;

        final bm = RegExp(r'border:\s*Border\(').firstMatch(block);
        if (bm == null) continue;
        final borderArgs = _balanced(block, bm.end - 1);
        if (borderArgs == null) continue;

        final colors = <String>{};
        for (final side in const ['top', 'left', 'right', 'bottom']) {
          final sm = RegExp(
            r'\b' + side + r':\s*BorderSide\(([^)]*)\)',
            dotAll: true,
          ).firstMatch(borderArgs);
          if (sm == null) continue;
          final cm = RegExp(r'color:\s*([^,\n]+)').firstMatch(sm.group(1)!);
          colors.add(cm == null ? 'NONE' : cm.group(1)!.trim());
        }
        if (colors.length > 1) {
          final line = '\n'.allMatches(src.substring(0, m.start)).length + 1;
          offenders.add('${entity.path}:$line  → sides: $colors');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason: 'Non-uniform Border + borderRadius will crash at paint:\n'
          '${offenders.join('\n')}\n'
          'Fix: Border.all(...), a top-only Border, or ClipRRect + an accent bar.',
    );
  });
}

/// Returns the substring from [open] (index of a '(') through its matching ')'.
String? _balanced(String s, int open) {
  var depth = 0;
  for (var i = open; i < s.length; i++) {
    if (s[i] == '(') depth++;
    if (s[i] == ')') {
      depth--;
      if (depth == 0) return s.substring(open, i + 1);
    }
  }
  return null;
}
