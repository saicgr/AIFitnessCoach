// Regression guard for "dead route" bugs — a `context.push('/foo')` /
// `context.go('/foo')` whose path was never registered with GoRouter, so the
// user lands on the router's `errorBuilder` ("Page not found: /foo").
//
// Row #118 (docs/qa/E2E_ISSUES_2026-07-28.md): the "Get Started Challenge
// complete!" toast's OPEN action, the "Open your crate" button, and the
// double-XP banner all pushed `/xp`, which no `GoRoute` in
// `lib/navigation/app_router*.dart` registers — a dead route on the
// first-run path. This test makes that whole CLASS of bug fail loudly:
// every string-literal `context.push('/…')` / `context.go('/…')` anywhere
// in `lib/` must resolve against a registered route path.
//
// Scope / deliberate limitations:
//  - Only STRING-LITERAL pushes are checked (no `$` interpolation) — a
//    dynamic path like `context.push('/workout/$id')` can't be statically
//    verified here and is skipped.
//  - Query strings are stripped before comparison (`'/chat?source=x'` is
//    checked as `/chat`) since GoRouter matches on path only.
//  - A registered path segment starting with `:` (e.g. `/workout/:id`) is
//    treated as a wildcard when matching a literal push against it.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every file under `lib/navigation/` that declares `GoRoute(path: ...)`.
List<File> _navigationFiles() {
  final dir = Directory('lib/navigation');
  return dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();
}

final _literalPathPattern = RegExp(r"path:\s*'([^']+)'");
final _routePathRefPattern = RegExp(r'path:\s*(\w+)\.routePath');
final _routePathConstPattern =
    RegExp(r"static const String routePath\s*=\s*'([^']+)'");

/// The full set of paths GoRouter will actually match: literal `path: '...'`
/// strings, plus `path: SomeScreen.routePath` references resolved by
/// scanning `lib/` for that screen's `static const String routePath`.
Set<String> _registeredRoutePaths() {
  final registered = <String>{};
  final unresolvedRefs = <String>{};

  for (final file in _navigationFiles()) {
    final text = file.readAsStringSync();
    for (final m in _literalPathPattern.allMatches(text)) {
      registered.add(m.group(1)!);
    }
    for (final m in _routePathRefPattern.allMatches(text)) {
      unresolvedRefs.add(m.group(1)!);
    }
  }

  if (unresolvedRefs.isNotEmpty) {
    for (final entry in Directory('lib').listSync(recursive: true)) {
      if (unresolvedRefs.isEmpty) break;
      if (entry is! File || !entry.path.endsWith('.dart')) continue;
      final text = entry.readAsStringSync();
      final resolvedNow = <String>[];
      for (final classname in unresolvedRefs) {
        if (!text.contains('class $classname')) continue;
        final m = _routePathConstPattern.firstMatch(text);
        if (m != null) {
          registered.add(m.group(1)!);
          resolvedNow.add(classname);
        }
      }
      unresolvedRefs.removeAll(resolvedNow);
    }
  }

  // Anything still unresolved means the test harness itself can't see the
  // constant — fail loudly rather than silently under-checking.
  expect(unresolvedRefs, isEmpty,
      reason: 'Could not resolve routePath reference(s) for: '
          '$unresolvedRefs — a GoRoute path: X.routePath whose class or '
          'const this script could not find. Update the test parser.');

  return registered;
}

/// A single `context.push('/…')` / `context.go('/…')` call site.
class _PushSite {
  final String path; // query-stripped
  final String location; // "file.dart:123"
  const _PushSite(this.path, this.location);
}

final _pushPattern = RegExp(r"context\.(?:push|go)\('([^'\$]+)'");

/// Every string-literal push/go call anywhere in `lib/`.
List<_PushSite> _allPushSites() {
  final sites = <_PushSite>[];
  for (final entry in Directory('lib').listSync(recursive: true)) {
    if (entry is! File || !entry.path.endsWith('.dart')) continue;
    final lines = entry.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      for (final m in _pushPattern.allMatches(lines[i])) {
        final raw = m.group(1)!;
        if (!raw.startsWith('/')) continue; // relative/named — not our scope
        final path = raw.split('?').first;
        if (path == '/') continue; // root is always valid (go_router base)
        sites.add(_PushSite(path, '${entry.path}:${i + 1}'));
      }
    }
  }
  return sites;
}

/// True if [pushed] (a literal, no params) is satisfied by [registered]
/// (may contain `:param` wildcard segments).
bool _pathMatchesRegistered(String pushed, String registered) {
  final p = pushed.split('/');
  final r = registered.split('/');
  if (p.length != r.length) return false;
  for (var i = 0; i < p.length; i++) {
    if (r[i].startsWith(':')) continue;
    if (p[i] != r[i]) return false;
  }
  return true;
}

void main() {
  test(
      'every context.push/go(\'/literal\') in lib/ resolves to a registered GoRoute',
      () {
    final registered = _registeredRoutePaths();
    expect(registered.length, greaterThan(100),
        reason: 'Sanity check: route parser found suspiciously few '
            'registered routes (${registered.length}) — likely a regex or '
            'path-glob regression in this test, not a real app change.');

    final deadPushes = <String>[];
    for (final site in _allPushSites()) {
      final isRegistered = registered.contains(site.path) ||
          registered.any((r) => _pathMatchesRegistered(site.path, r));
      if (!isRegistered) {
        deadPushes.add('${site.location} -> ${site.path}');
      }
    }

    expect(
      deadPushes,
      isEmpty,
      reason: 'Found context.push/go() call(s) targeting a route path that '
          'no GoRoute registers (dead route — user hits "Page not found"):\n'
          '${deadPushes.join('\n')}',
    );
  });
}
